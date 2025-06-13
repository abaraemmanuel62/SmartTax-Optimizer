# Smart Tax Optimizer

An algorithmic tax optimization system built as a smart contract on the Stacks blockchain using Clarity. This system provides tax calculations, optimization strategies, and financial planning recommendations for individual taxpayers.

## Features

- **Tax Calculation Engine**: Automated tax liability calculations based on current tax brackets
- **Optimization Strategies**: AI-driven recommendations for tax savings
- **Multi-Filing Status Support**: Single, Married Filing Jointly, Married Filing Separately, Head of Household
- **Income Source Management**: Track multiple income types (salary, business, investment, rental)
- **Deduction Tracking**: Above-the-line and itemized deduction management
- **Marginal Tax Rate Analysis**: Real-time marginal tax rate calculations
- **Strategy Recommendations**: Retirement contributions, tax-loss harvesting, charitable giving optimization

## Architecture

The contract is structured with the following main components:

- **Data Structures**: Taxpayer profiles, income sources, deductions, tax brackets
- **Calculation Engine**: AGI calculation, tax liability computation, marginal rate analysis
- **Optimization Algorithms**: Strategy generation and savings calculations
- **Administrative Functions**: Contract management and tax bracket initialization

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/smart-tax-optimizer.git
cd smart-tax-optimizer
```

2. Install dependencies:
```bash
npm install
```

3. Install Clarinet (Stacks development tool):
```bash
npm install -g @hirosystems/clarinet-cli
```

## Usage

### Deploy Contract

```bash
clarinet deploy
```

### Initialize Tax Brackets

```bash
clarinet call smarttax-optimizer initialize-tax-brackets
```

### Register a Taxpayer

```bash
clarinet call smarttax-optimizer register-taxpayer u1 "John Doe" u1 u35 u2 u2024
```

### Add Income Source

```bash
clarinet call smarttax-optimizer add-income-source u1 u1 u1 u75000 u15000 true
```

### Calculate Tax Liability

```bash
clarinet call smarttax-optimizer calculate-tax-liability u1
```

### Generate Optimization Strategies

```bash
clarinet call smarttax-optimizer generate-optimization-strategies u1
```

## API Reference

### Public Functions

#### `register-taxpayer`
Registers a new taxpayer in the system.

**Parameters:**
- `taxpayer-id` (uint): Unique identifier
- `name` (string-ascii 100): Taxpayer name
- `filing-status` (uint): Filing status (1-4)
- `age` (uint): Taxpayer age
- `dependents` (uint): Number of dependents
- `tax-year` (uint): Tax year

**Returns:** `(response uint uint)`

#### `add-income-source`
Adds an income source for a taxpayer.

**Parameters:**
- `taxpayer-id` (uint): Taxpayer identifier
- `income-id` (uint): Income source identifier
- `income-type` (uint): Type of income (1-4)
- `amount` (uint): Income amount
- `tax-withheld` (uint): Tax already withheld
- `is-taxable` (bool): Whether income is taxable

**Returns:** `(response bool uint)`

#### `add-deduction`
Adds a deduction for a taxpayer.

**Parameters:**
- `taxpayer-id` (uint): Taxpayer identifier
- `deduction-id` (uint): Deduction identifier
- `deduction-type` (uint): Type of deduction
- `amount` (uint): Deduction amount
- `is-above-line` (bool): Above-the-line deduction flag
- `is-itemized` (bool): Itemized deduction flag

**Returns:** `(response bool uint)`

#### `generate-optimization-strategies`
Generates tax optimization strategies for a taxpayer.

**Parameters:**
- `taxpayer-id` (uint): Taxpayer identifier

**Returns:** `(response bool uint)`

### Read-Only Functions

#### `calculate-tax-liability`
Calculates the tax liability for a taxpayer.

**Parameters:**
- `taxpayer-id` (uint): Taxpayer identifier

**Returns:** `(response uint uint)`

#### `calculate-adjusted-gross-income`
Calculates the adjusted gross income (AGI).

**Parameters:**
- `taxpayer-id` (uint): Taxpayer identifier

**Returns:** `(response uint uint)`

#### `get-tax-summary`
Returns a comprehensive tax summary.

**Parameters:**
- `taxpayer-id` (uint): Taxpayer identifier

**Returns:** `(response {agi: uint, tax-liability: uint, marginal-rate: uint} uint)`

#### `get-taxpayer-info`
Retrieves taxpayer information.

**Parameters:**
- `taxpayer-id` (uint): Taxpayer identifier

**Returns:** `(optional {name: string-ascii 100, filing-status: uint, age: uint, dependents: uint, tax-year: uint, total-income: uint, total-deductions: uint, tax-credits: uint})`

## Constants

### Filing Status
- `FILING-STATUS-SINGLE`: 1
- `FILING-STATUS-MARRIED-JOINT`: 2
- `FILING-STATUS-MARRIED-SEPARATE`: 3
- `FILING-STATUS-HEAD-OF-HOUSEHOLD`: 4

### Income Types
- `INCOME-TYPE-SALARY`: 1
- `INCOME-TYPE-BUSINESS`: 2
- `INCOME-TYPE-INVESTMENT`: 3
- `INCOME-TYPE-RENTAL`: 4

### Error Codes
- `ERR-UNAUTHORIZED`: 100
- `ERR-INVALID-TAXPAYER`: 101
- `ERR-INVALID-INCOME`: 102
- `ERR-INVALID-DEDUCTION`: 103
- `ERR-CALCULATION-ERROR`: 104

## Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage:

```bash
npm run test:coverage
```

The test suite includes:
- Taxpayer registration validation
- Income and deduction management
- Tax calculation accuracy
- Optimization strategy generation
- Error handling and edge cases

## Tax Brackets (2024)

### Single Filers
- 10%: $0 - $11,000
- 12%: $11,001 - $44,725
- 22%: $44,726 - $95,375
- 24%: $95,376 - $182,050

### Married Filing Jointly
- 10%: $0 - $22,000
- 12%: $22,001 - $89,450
- 22%: $89,451 - $190,750

## Optimization Strategies

The system provides three main optimization strategies:

### 1. Retirement Contribution Maximization
- **Description**: Maximize pre-tax retirement contributions to reduce taxable income
- **Complexity**: Low
- **Potential Savings**: Based on marginal tax rate × max contribution limit

### 2. Tax-Loss Harvesting
- **Description**: Realize investment losses to offset capital gains
- **Complexity**: Medium
- **Potential Savings**: Based on harvestable losses × marginal tax rate

### 3. Charitable Giving Optimization
- **Description**: Optimize charitable contributions for maximum tax benefit
- **Complexity**: Medium
- **Potential Savings**: Based on additional giving × marginal tax rate

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development

### Prerequisites
- Node.js 16+
- Clarinet CLI
- Stacks blockchain testnet access

### Setup
```bash
# Install dependencies
npm install

# Run tests
npm test

# Deploy to testnet
clarinet deploy --testnet

# Check contract
clarinet check
```

## Security Considerations

- All calculations are performed on-chain for transparency
- Input validation prevents invalid data entry
- Error handling ensures graceful failure modes
- Access controls protect administrative functions

## Roadmap

- [ ] Multi-year tax planning
- [ ] State tax calculations
- [ ] Business entity optimization
- [ ] Real-time market data integration
- [ ] Advanced estate planning strategies
- [ ] Tax document generation
- [ ] Mobile app integration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This software is for educational and informational purposes only. It should not be considered as professional tax advice. Always consult with a qualified tax professional for your specific situation.

## Support

For support, please open an issue on GitHub or contact the development team.

## Acknowledgments

- Stacks blockchain community
- Clarity language documentation
- Tax policy research contributors