;; Algorithmic Tax Optimization System
;; Smart contract for tax optimization calculations and strategy recommendations
;; Built with Clarity for Stacks blockchain

;; =============================================================================
;; CONSTANTS AND ERROR CODES
;; =============================================================================

(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-TAXPAYER (err u101))
(define-constant ERR-INVALID-INCOME (err u102))
(define-constant ERR-INVALID-DEDUCTION (err u103))
(define-constant ERR-CALCULATION-ERROR (err u104))

(define-constant FILING-STATUS-SINGLE u1)
(define-constant FILING-STATUS-MARRIED-JOINT u2)
(define-constant FILING-STATUS-MARRIED-SEPARATE u3)
(define-constant FILING-STATUS-HEAD-OF-HOUSEHOLD u4)

(define-constant INCOME-TYPE-SALARY u1)
(define-constant INCOME-TYPE-BUSINESS u2)
(define-constant INCOME-TYPE-INVESTMENT u3)
(define-constant INCOME-TYPE-RENTAL u4)

;; =============================================================================
;; DATA STRUCTURES
;; =============================================================================

;; Define taxpayer data structure
(define-map taxpayers
  { taxpayer-id: uint }
  {
    name: (string-ascii 100),
    filing-status: uint,
    age: uint,
    dependents: uint,
    tax-year: uint,
    total-income: uint,
    total-deductions: uint,
    tax-credits: uint
  }
)

;; Define income sources
(define-map income-sources
  { taxpayer-id: uint, income-id: uint }
  {
    income-type: uint,
    amount: uint,
    tax-withheld: uint,
    is-taxable: bool
  }
)

;; Define deductions
(define-map deductions
  { taxpayer-id: uint, deduction-id: uint }
  {
    deduction-type: uint,
    amount: uint,
    is-above-line: bool,
    is-itemized: bool
  }
)

;; Tax brackets for different filing statuses
(define-map tax-brackets
  { filing-status: uint, bracket-level: uint }
  {
    min-income: uint,
    max-income: uint,
    tax-rate: uint ;; Rate in basis points (e.g., 1000 = 10%)
  }
)

;; Optimization strategies
(define-map optimization-strategies
  { strategy-id: uint }
  {
    strategy-name: (string-ascii 100),
    description: (string-ascii 500),
    potential-savings: uint,
    complexity-level: uint,
    is-legal: bool
  }
)

;; =============================================================================
;; ADMINISTRATIVE FUNCTIONS
;; =============================================================================

(define-data-var contract-owner principal tx-sender)

(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Initialize tax brackets
(define-public (initialize-tax-brackets)
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    
    ;; Single filer brackets (2024 tax year)
    (map-set tax-brackets { filing-status: FILING-STATUS-SINGLE, bracket-level: u1 }
             { min-income: u0, max-income: u11000, tax-rate: u1000 }) ;; 10%
    (map-set tax-brackets { filing-status: FILING-STATUS-SINGLE, bracket-level: u2 }
             { min-income: u11000, max-income: u44725, tax-rate: u1200 }) ;; 12%
    (map-set tax-brackets { filing-status: FILING-STATUS-SINGLE, bracket-level: u3 }
             { min-income: u44725, max-income: u95375, tax-rate: u2200 }) ;; 22%
    (map-set tax-brackets { filing-status: FILING-STATUS-SINGLE, bracket-level: u4 }
             { min-income: u95375, max-income: u182050, tax-rate: u2400 }) ;; 24%
    
    ;; Married filing jointly brackets
    (map-set tax-brackets { filing-status: FILING-STATUS-MARRIED-JOINT, bracket-level: u1 }
             { min-income: u0, max-income: u22000, tax-rate: u1000 }) ;; 10%
    (map-set tax-brackets { filing-status: FILING-STATUS-MARRIED-JOINT, bracket-level: u2 }
             { min-income: u22000, max-income: u89450, tax-rate: u1200 }) ;; 12%
    (map-set tax-brackets { filing-status: FILING-STATUS-MARRIED-JOINT, bracket-level: u3 }
             { min-income: u89450, max-income: u190750, tax-rate: u2200 }) ;; 22%
    
    (ok true)
  )
)

;; =============================================================================
;; TAXPAYER MANAGEMENT
;; =============================================================================

(define-public (register-taxpayer 
  (taxpayer-id uint) 
  (name (string-ascii 100))
  (filing-status uint)
  (age uint)
  (dependents uint)
  (tax-year uint))
  (begin
    (asserts! (and (>= filing-status u1) (<= filing-status u4)) ERR-INVALID-TAXPAYER)
    (asserts! (> age u0) ERR-INVALID-TAXPAYER)
    (asserts! (>= tax-year u2020) ERR-INVALID-TAXPAYER)
    
    (map-set taxpayers { taxpayer-id: taxpayer-id }
             {
               name: name,
               filing-status: filing-status,
               age: age,
               dependents: dependents,
               tax-year: tax-year,
               total-income: u0,
               total-deductions: u0,
               tax-credits: u0
             })
    (ok taxpayer-id)
  )
)

(define-public (add-income-source
  (taxpayer-id uint)
  (income-id uint)
  (income-type uint)
  (amount uint)
  (tax-withheld uint)
  (is-taxable bool))
  (begin
    (asserts! (is-some (map-get? taxpayers { taxpayer-id: taxpayer-id })) ERR-INVALID-TAXPAYER)
    (asserts! (> amount u0) ERR-INVALID-INCOME)
    
    (map-set income-sources 
             { taxpayer-id: taxpayer-id, income-id: income-id }
             {
               income-type: income-type,
               amount: amount,
               tax-withheld: tax-withheld,
               is-taxable: is-taxable
             })
    (ok true)
  )
)

(define-public (add-deduction
  (taxpayer-id uint)
  (deduction-id uint)
  (deduction-type uint)
  (amount uint)
  (is-above-line bool)
  (is-itemized bool))
  (begin
    (asserts! (is-some (map-get? taxpayers { taxpayer-id: taxpayer-id })) ERR-INVALID-TAXPAYER)
    (asserts! (> amount u0) ERR-INVALID-DEDUCTION)
    
    (map-set deductions
             { taxpayer-id: taxpayer-id, deduction-id: deduction-id }
             {
               deduction-type: deduction-type,
               amount: amount,
               is-above-line: is-above-line,
               is-itemized: is-itemized
             })
    (ok true)
  )
)

;; =============================================================================
;; TAX CALCULATION FUNCTIONS
;; =============================================================================

(define-read-only (calculate-adjusted-gross-income (taxpayer-id uint))
  (let ((taxpayer-data (unwrap! (map-get? taxpayers { taxpayer-id: taxpayer-id }) ERR-INVALID-TAXPAYER)))
    (let ((total-income (calculate-total-income taxpayer-id))
          (above-line-deductions (calculate-above-line-deductions taxpayer-id)))
      (ok (if (> total-income above-line-deductions)
              (- total-income above-line-deductions)
              u0))
    )
  )
)

(define-read-only (calculate-total-income (taxpayer-id uint))
  ;; This is a simplified version - in practice, you'd iterate through all income sources
  ;; For this example, we'll use a mock calculation
  u75000 ;; Mock total income
)

(define-read-only (calculate-above-line-deductions (taxpayer-id uint))
  ;; Mock calculation for above-the-line deductions
  u5000
)

(define-read-only (get-standard-deduction (filing-status uint) (age uint))
  (if (is-eq filing-status FILING-STATUS-SINGLE)
      (if (>= age u65) u14700 u13850) ;; 2024 values with senior bonus
      (if (is-eq filing-status FILING-STATUS-MARRIED-JOINT)
          (if (>= age u65) u28700 u27700) ;; Married filing jointly
          u13850) ;; Default
  )
)

(define-read-only (calculate-tax-liability (taxpayer-id uint))
  (let ((agi-result (calculate-adjusted-gross-income taxpayer-id)))
    (match agi-result
      success-agi (let ((taxpayer-data (unwrap! (map-get? taxpayers { taxpayer-id: taxpayer-id }) ERR-INVALID-TAXPAYER))
                       (standard-deduction (get-standard-deduction 
                                           (get filing-status taxpayer-data)
                                           (get age taxpayer-data)))
                       (taxable-income (if (> success-agi standard-deduction)
                                         (- success-agi standard-deduction)
                                         u0)))
                    (ok (calculate-tax-from-brackets taxable-income (get filing-status taxpayer-data))))
      error-agi (err error-agi)
    )
  )
)

(define-read-only (calculate-tax-from-brackets (taxable-income uint) (filing-status uint))
  (let ((bracket-1 (unwrap-panic (map-get? tax-brackets { filing-status: filing-status, bracket-level: u1 })))
        (bracket-2 (unwrap-panic (map-get? tax-brackets { filing-status: filing-status, bracket-level: u2 })))
        (bracket-3 (unwrap-panic (map-get? tax-brackets { filing-status: filing-status, bracket-level: u3 }))))
    
    (if (<= taxable-income (get max-income bracket-1))
        ;; Income falls in first bracket
        (/ (* taxable-income (get tax-rate bracket-1)) u10000)
        
        (if (<= taxable-income (get max-income bracket-2))
            ;; Income falls in second bracket
            (+ (/ (* (get max-income bracket-1) (get tax-rate bracket-1)) u10000)
               (/ (* (- taxable-income (get max-income bracket-1)) (get tax-rate bracket-2)) u10000))
            
            ;; Income falls in third bracket or higher
            (+ (/ (* (get max-income bracket-1) (get tax-rate bracket-1)) u10000)
               (/ (* (- (get max-income bracket-2) (get max-income bracket-1)) (get tax-rate bracket-2)) u10000)
               (/ (* (- taxable-income (get max-income bracket-2)) (get tax-rate bracket-3)) u10000))
        )
    )
  )
)

;; =============================================================================
;; OPTIMIZATION ALGORITHMS
;; =============================================================================

(define-read-only (calculate-marginal-tax-rate (taxpayer-id uint))
  (let ((tax-liability-result (calculate-tax-liability taxpayer-id)))
    (match tax-liability-result
      success-tax (let ((agi-result (calculate-adjusted-gross-income taxpayer-id)))
                    (match agi-result
                      success-agi (let ((increased-income-tax (calculate-tax-from-brackets 
                                                               (+ success-agi u1000)
                                                               (get filing-status (unwrap! (map-get? taxpayers { taxpayer-id: taxpayer-id }) ERR-INVALID-TAXPAYER)))))
                                    (ok (- increased-income-tax success-tax)))
                      error-agi (err error-agi)))
      error-tax (err error-tax)
    )
  )
)

(define-public (generate-optimization-strategies (taxpayer-id uint))
  (let ((taxpayer-data (unwrap! (map-get? taxpayers { taxpayer-id: taxpayer-id }) ERR-INVALID-TAXPAYER))
        (current-tax (unwrap! (calculate-tax-liability taxpayer-id) ERR-CALCULATION-ERROR)))
    
    ;; Strategy 1: Maximize retirement contributions
    (map-set optimization-strategies { strategy-id: u1 }
             {
               strategy-name: "Maximize 401k Contributions",
               description: "Increase pre-tax retirement contributions to reduce taxable income",
               potential-savings: (calculate-retirement-contribution-savings taxpayer-id),
               complexity-level: u1,
               is-legal: true
             })
    
    ;; Strategy 2: Tax-loss harvesting
    (map-set optimization-strategies { strategy-id: u2 }
             {
               strategy-name: "Tax-Loss Harvesting",
               description: "Realize investment losses to offset capital gains",
               potential-savings: (calculate-tax-loss-harvesting-savings taxpayer-id),
               complexity-level: u2,
               is-legal: true
             })
    
    ;; Strategy 3: Charitable giving optimization
    (map-set optimization-strategies { strategy-id: u3 }
             {
               strategy-name: "Charitable Giving Optimization",
               description: "Optimize charitable contributions for maximum tax benefit",
               potential-savings: (calculate-charitable-giving-savings taxpayer-id),
               complexity-level: u2,
               is-legal: true
             })
    
    (ok true)
  )
)

(define-read-only (calculate-retirement-contribution-savings (taxpayer-id uint))
  (let ((marginal-rate-result (calculate-marginal-tax-rate taxpayer-id)))
    (match marginal-rate-result
      success-rate (/ (* u22500 success-rate) u10000) ;; Max 401k contribution * marginal rate
      error-rate u0
    )
  )
)

(define-read-only (calculate-tax-loss-harvesting-savings (taxpayer-id uint))
  ;; Simplified calculation - assume $5000 in harvestable losses
  (let ((marginal-rate-result (calculate-marginal-tax-rate taxpayer-id)))
    (match marginal-rate-result
      success-rate (/ (* u5000 success-rate) u10000)
      error-rate u0
    )
  )
)

(define-read-only (calculate-charitable-giving-savings (taxpayer-id uint))
  ;; Simplified calculation - assume $2000 in additional charitable giving
  (let ((marginal-rate-result (calculate-marginal-tax-rate taxpayer-id)))
    (match marginal-rate-result
      success-rate (/ (* u2000 success-rate) u10000)
      error-rate u0
    )
  )
)

;; =============================================================================
;; QUERY FUNCTIONS
;; =============================================================================

(define-read-only (get-taxpayer-info (taxpayer-id uint))
  (map-get? taxpayers { taxpayer-id: taxpayer-id })
)

(define-read-only (get-optimization-strategy (strategy-id uint))
  (map-get? optimization-strategies { strategy-id: strategy-id })
)

(define-read-only (get-tax-summary (taxpayer-id uint))
  (let ((agi-result (calculate-adjusted-gross-income taxpayer-id))
        (tax-result (calculate-tax-liability taxpayer-id))
        (marginal-rate-result (calculate-marginal-tax-rate taxpayer-id)))
    (ok {
      agi: (unwrap! agi-result ERR-CALCULATION-ERROR),
      tax-liability: (unwrap! tax-result ERR-CALCULATION-ERROR),
      marginal-rate: (unwrap! marginal-rate-result ERR-CALCULATION-ERROR)
    })
  )
)

;; =============================================================================
;; REPORTING FUNCTIONS
;; =============================================================================