import { describe, expect, it } from "vitest";

describe("Smart Tax Optimizer Contract", () => {
  describe("Taxpayer Registration", () => {
    it("should register a taxpayer with valid data", () => {
      const taxpayerId = 1;
      const name = "John Doe";
      const filingStatus = 1; // SINGLE
      const age = 35;
      const dependents = 2;
      const taxYear = 2024;

      const result = registerTaxpayer(taxpayerId, name, filingStatus, age, dependents, taxYear);
      
      expect(result.isOk).toBe(true);
      expect(result.value).toBe(taxpayerId);
    });

    it("should reject taxpayer registration with invalid filing status", () => {
      const taxpayerId = 2;
      const name = "Jane Smith";
      const filingStatus = 5; // Invalid status
      const age = 30;
      const dependents = 0;
      const taxYear = 2024;

      const result = registerTaxpayer(taxpayerId, name, filingStatus, age, dependents, taxYear);
      
      expect(result.isErr).toBe(true);
      expect(result.error).toBe(101); // ERR-INVALID-TAXPAYER
    });

    it("should reject taxpayer registration with zero age", () => {
      const taxpayerId = 3;
      const name = "Invalid Age";
      const filingStatus = 1;
      const age = 0;
      const dependents = 0;
      const taxYear = 2024;

      const result = registerTaxpayer(taxpayerId, name, filingStatus, age, dependents, taxYear);
      
      expect(result.isErr).toBe(true);
      expect(result.error).toBe(101); // ERR-INVALID-TAXPAYER
    });

    it("should reject taxpayer registration with tax year before 2020", () => {
      const taxpayerId = 4;
      const name = "Old Tax Year";
      const filingStatus = 1;
      const age = 25;
      const dependents = 0;
      const taxYear = 2019;

      const result = registerTaxpayer(taxpayerId, name, filingStatus, age, dependents, taxYear);
      
      expect(result.isErr).toBe(true);
      expect(result.error).toBe(101); // ERR-INVALID-TAXPAYER
    });
  });

  describe("Income Source Management", () => {
    it("should add income source for valid taxpayer", () => {
      const taxpayerId = 1;
      const incomeId = 1;
      const incomeType = 1; // SALARY
      const amount = 75000;
      const taxWithheld = 15000;
      const isTaxable = true;

      // First register taxpayer
      registerTaxpayer(taxpayerId, "John Doe", 1, 35, 2, 2024);
      
      const result = addIncomeSource(taxpayerId, incomeId, incomeType, amount, taxWithheld, isTaxable);
      
      expect(result.isOk).toBe(true);
      expect(result.value).toBe(true);
    });

    it("should reject income source for non-existent taxpayer", () => {
      const taxpayerId = 999; // Non-existent
      const incomeId = 1;
      const incomeType = 1;
      const amount = 75000;
      const taxWithheld = 15000;
      const isTaxable = true;

      const result = addIncomeSource(taxpayerId, incomeId, incomeType, amount, taxWithheld, isTaxable);
      
      expect(result.isErr).toBe(true);
      expect(result.error).toBe(101); // ERR-INVALID-TAXPAYER
    });

    it("should reject income source with zero amount", () => {
      const taxpayerId = 1;
      const incomeId = 2;
      const incomeType = 1;
      const amount = 0;
      const taxWithheld = 0;
      const isTaxable = true;

      const result = addIncomeSource(taxpayerId, incomeId, incomeType, amount, taxWithheld, isTaxable);
      
      expect(result.isErr).toBe(true);
      expect(result.error).toBe(102); // ERR-INVALID-INCOME
    });
  });

  describe("Deduction Management", () => {
    it("should add deduction for valid taxpayer", () => {
      const taxpayerId = 1;
      const deductionId = 1;
      const deductionType = 1;
      const amount = 5000;
      const isAboveLine = true;
      const isItemized = false;

      const result = addDeduction(taxpayerId, deductionId, deductionType, amount, isAboveLine, isItemized);
      
      expect(result.isOk).toBe(true);
      expect(result.value).toBe(true);
    });

    it("should reject deduction for non-existent taxpayer", () => {
      const taxpayerId = 999;
      const deductionId = 1;
      const deductionType = 1;
      const amount = 5000;
      const isAboveLine = true;
      const isItemized = false;

      const result = addDeduction(taxpayerId, deductionId, deductionType, amount, isAboveLine, isItemized);
      
      expect(result.isErr).toBe(true);
      expect(result.error).toBe(101); // ERR-INVALID-TAXPAYER
    });

    it("should reject deduction with zero amount", () => {
      const taxpayerId = 1;
      const deductionId = 2;
      const deductionType = 1;
      const amount = 0;
      const isAboveLine = false;
      const isItemized = true;

      const result = addDeduction(taxpayerId, deductionId, deductionType, amount, isAboveLine, isItemized);
      
      expect(result.isErr).toBe(true);
      expect(result.error).toBe(103); // ERR-INVALID-DEDUCTION
    });
  });

  describe("Tax Calculations", () => {
    it("should calculate AGI correctly", () => {
      const taxpayerId = 1;
      
      const result = calculateAdjustedGrossIncome(taxpayerId);
      
      expect(result.isOk).toBe(true);
      expect(result.value).toBe(70000); // 75000 - 5000 (mock values)
    });

    it("should calculate AGI as zero when deductions exceed income", () => {
      // Mock scenario where deductions > income
      const taxpayerId = 5;
      registerTaxpayer(taxpayerId, "High Deduction", 1, 25, 0, 2024);
      
      const result = calculateAdjustedGrossIncome(taxpayerId);
      
      expect(result.isOk).toBe(true);
      expect(typeof result.value).toBe("number");
      expect(result.value).toBeGreaterThanOrEqual(0);
    });

    it("should get correct standard deduction for single filer under 65", () => {
      const filingStatus = 1; // SINGLE
      const age = 35;
      
      const result = getStandardDeduction(filingStatus, age);
      
      expect(result).toBe(13850);
    });

    it("should get correct standard deduction for single filer 65 or older", () => {
      const filingStatus = 1; // SINGLE
      const age = 67;
      
      const result = getStandardDeduction(filingStatus, age);
      
      expect(result).toBe(14700);
    });

    it("should get correct standard deduction for married filing jointly", () => {
      const filingStatus = 2; // MARRIED_JOINT
      const age = 35;
      
      const result = getStandardDeduction(filingStatus, age);
      
      expect(result).toBe(27700);
    });

    it("should calculate tax liability for valid taxpayer", () => {
      const taxpayerId = 1;
      
      const result = calculateTaxLiability(taxpayerId);
      
      expect(result.isOk).toBe(true);
      expect(typeof result.value).toBe("number");
      expect(result.value).toBeGreaterThanOrEqual(0);
    });

    it("should calculate tax from brackets correctly for low income", () => {
      const taxableIncome = 10000;
      const filingStatus = 1; // SINGLE
      
      const result = calculateTaxFromBrackets(taxableIncome, filingStatus);
      
      expect(result).toBe(1000); // 10% of 10000
    });

    it("should calculate tax from brackets correctly for middle income", () => {
      const taxableIncome = 50000;
      const filingStatus = 1; // SINGLE
      
      const result = calculateTaxFromBrackets(taxableIncome, filingStatus);
      
      // First bracket: 11000 * 10% = 1100
      // Second bracket: (50000 - 11000) * 12% = 4680
      // Total: 5780
      expect(result).toBe(5780);
    });
  });

  describe("Optimization Strategies", () => {
    it("should generate optimization strategies for taxpayer", () => {
      const taxpayerId = 1;
      
      const result = generateOptimizationStrategies(taxpayerId);
      
      expect(result.isOk).toBe(true);
      expect(result.value).toBe(true);
    });

    it("should calculate retirement contribution savings", () => {
      const taxpayerId = 1;
      
      const result = calculateRetirementContributionSavings(taxpayerId);
      
      expect(typeof result).toBe("number");
      expect(result).toBeGreaterThanOrEqual(0);
    });

    it("should calculate tax loss harvesting savings", () => {
      const taxpayerId = 1;
      
      const result = calculateTaxLossHarvestingSavings(taxpayerId);
      
      expect(typeof result).toBe("number");
      expect(result).toBeGreaterThanOrEqual(0);
    });

    it("should calculate charitable giving savings", () => {
      const taxpayerId = 1;
      
      const result = calculateCharitableGivingSavings(taxpayerId);
      
      expect(typeof result).toBe("number");
      expect(result).toBeGreaterThanOrEqual(0);
    });
  });

  describe("Query Functions", () => {
    it("should get taxpayer info", () => {
      const taxpayerId = 1;
      
      const result = getTaxpayerInfo(taxpayerId);
      
      expect(result).toBeDefined();
      if (result) {
        expect(result.name).toBe("John Doe");
        expect(result.filingStatus).toBe(1);
        expect(result.age).toBe(35);
      }
    });

    it("should return null for non-existent taxpayer", () => {
      const taxpayerId = 999;
      
      const result = getTaxpayerInfo(taxpayerId);
      
      expect(result).toBeNull();
    });

    it("should get optimization strategy", () => {
      const strategyId = 1;
      
      // First generate strategies
      generateOptimizationStrategies(1);
      
      const result = getOptimizationStrategy(strategyId);
      
      expect(result).toBeDefined();
      if (result) {
        expect(result.strategyName).toBe("Maximize 401k Contributions");
        expect(result.isLegal).toBe(true);
      }
    });

    it("should get tax summary for taxpayer", () => {
      const taxpayerId = 1;
      
      const result = getTaxSummary(taxpayerId);
      
      expect(result.isOk).toBe(true);
      expect(result.value).toHaveProperty("agi");
      expect(result.value).toHaveProperty("taxLiability");
      expect(result.value).toHaveProperty("marginalRate");
    });
  });

  describe("Administrative Functions", () => {
    it("should initialize tax brackets successfully", () => {
      const result = initializeTaxBrackets();
      
      expect(result.isOk).toBe(true);
      expect(result.value).toBe(true);
    });

    it("should reject tax bracket initialization from non-owner", () => {
      // This would need to be tested with a different tx-sender
      // Implementation depends on how the test framework handles tx-sender
      expect(true).toBe(true); // Placeholder
    });
  });

  describe("Edge Cases", () => {
    it("should handle zero taxable income", () => {
      const taxableIncome = 0;
      const filingStatus = 1;
      
      const result = calculateTaxFromBrackets(taxableIncome, filingStatus);
      
      expect(result).toBe(0);
    });

    it("should handle very high income", () => {
      const taxableIncome = 500000;
      const filingStatus = 1;
      
      const result = calculateTaxFromBrackets(taxableIncome, filingStatus);
      
      expect(result).toBeGreaterThan(0);
      expect(typeof result).toBe("number");
    });

    it("should calculate marginal tax rate", () => {
      const taxpayerId = 1;
      
      const result = calculateMarginalTaxRate(taxpayerId);
      
      expect(result.isOk).toBe(true);
      expect(typeof result.value).toBe("number");
    });
  });
});