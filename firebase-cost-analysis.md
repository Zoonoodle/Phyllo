# NutriSync Firebase & AI Cost Analysis
Generated: 2025-09-02

## Current Setup
- **Meal Analysis**: Gemini 2.0 Flash Thinking (gemini-2.0-flash-thinking-exp-1219)
- **Window Generation**: Gemini 2.0 Flash (gemini-2.0-flash-exp)
- **Max Output Tokens**: 8192 per request

## Cost Breakdown for 1000 Users

### 1. Gemini AI Costs

#### Current Models (Gemini 2.0 Flash)
**Pricing:**
- Input: $0.01 per 1M tokens
- Output: $0.04 per 1M tokens

**Per User Daily:**
- 5 meal scans × ~1,500 input tokens = 7,500 tokens
- 5 meal scans × ~500 output tokens = 2,500 tokens
- 1 window generation × ~2,000 input tokens = 2,000 tokens
- 1 window generation × ~1,000 output tokens = 1,000 tokens

**Total per user/day:**
- Input: 9,500 tokens
- Output: 3,500 tokens

**Monthly costs (1000 users):**
- Input: 1000 × 30 × 9,500 = 285M tokens × $0.00001 = **$2.85**
- Output: 1000 × 30 × 3,500 = 105M tokens × $0.00004 = **$4.20**
- **Total Gemini 2.0 Flash: $7.05/month**

#### Upgraded to Gemini 2.5 Pro (Proposed)
**Pricing:**
- Input: $1.25 per 1M tokens
- Output: $5.00 per 1M tokens

**Same token usage:**
- Input: 285M tokens × $0.00125 = **$356.25**
- Output: 105M tokens × $0.005 = **$525.00**
- **Total Gemini 2.5 Pro: $881.25/month**

### 2. Firebase Costs

#### Firestore
**Pricing:**
- Reads: $0.06 per 100,000
- Writes: $0.18 per 100,000
- Storage: $0.18 per GB

**Daily operations per user:**
- Reads: ~50 (meals, windows, profile, check-ins)
- Writes: ~15 (5 meals, 1 window update, check-ins)

**Monthly (1000 users):**
- Reads: 1000 × 30 × 50 = 1.5M × $0.0006 = **$0.90**
- Writes: 1000 × 30 × 15 = 450K × $0.0018 = **$0.81**
- Storage: ~10MB/user × 1000 = 10GB × $0.18 = **$1.80**
- **Total Firestore: $3.51/month**

#### Firebase Storage (Meal Photos)
**Pricing:**
- Storage: $0.026 per GB
- Operations: $0.05 per 10,000
- Bandwidth: $0.12 per GB

**Per user:**
- 5 photos/day × 500KB = 2.5MB/day
- Auto-delete after 24 hours = 2.5MB storage max

**Monthly (1000 users):**
- Storage: 1000 × 2.5MB = 2.5GB × $0.026 = **$0.07**
- Operations: 1000 × 30 × 10 = 300K × $0.005 = **$1.50**
- Bandwidth: 1000 × 30 × 2.5MB = 75GB × $0.12 = **$9.00**
- **Total Storage: $10.57/month**

#### Firebase Auth
- Free tier covers 50K MAU
- **Total Auth: $0/month**

### 3. Total Monthly Costs

#### With Current Setup (Gemini 2.0 Flash)
- Gemini AI: $7.05
- Firestore: $3.51
- Storage: $10.57
- **TOTAL: $21.13/month** ($0.021 per user)

#### With Gemini 2.5 Pro Upgrade
- Gemini AI: $881.25
- Firestore: $3.51
- Storage: $10.57
- **TOTAL: $895.33/month** ($0.90 per user)

## Cost Optimization Strategies

### 1. Hybrid AI Approach (RECOMMENDED)
- Use Gemini 2.0 Flash for simple meals (single items, packaged foods)
- Use Gemini 2.5 Pro only for complex meals (multiple items, restaurant dishes)
- Estimated 70/30 split = **$272/month** ($0.27 per user)

### 2. Caching Strategy
- Cache common food items locally
- Skip AI for repeated meals within 7 days
- Estimated 30% reduction = **$14.79/month**

### 3. Image Optimization
- Compress to 300KB (from 500KB)
- Reduce bandwidth by 40% = Save $3.60/month

### 4. Batch Window Generation
- Generate weekly windows instead of daily
- Reduces API calls by 85%
- Minor savings due to low current cost

### 5. Progressive Enhancement
- Start with Gemini 2.0 Flash
- Offer "Pro Analysis" as premium feature ($2.99/month)
- Users who want better accuracy pay extra

## Recommendations

1. **Keep Gemini 2.0 Flash for MVP/TestFlight**
   - Current $21/month for 1000 users is sustainable
   - Focus on user acquisition first

2. **Implement Hybrid Approach for Scale**
   - Add confidence scoring to determine model selection
   - Monitor accuracy metrics

3. **Consider Freemium Model**
   - Free: 3 scans/day with Flash
   - Pro ($4.99/mo): Unlimited with 2.5 Pro

4. **Optimize Before Scaling**
   - Implement caching
   - Reduce image sizes
   - Batch operations where possible

## Break-Even Analysis

At $4.99/month subscription:
- Current setup: Need 5 paying users per 1000 to break even
- With 2.5 Pro: Need 180 paying users per 1000 to break even
- Hybrid approach: Need 55 paying users per 1000 to break even

## Conclusion

Current Gemini 2.0 Flash setup is extremely cost-effective at $0.021 per user/month. Upgrading to Gemini 2.5 Pro increases costs 42x. Recommend staying with current setup for TestFlight and implementing hybrid approach only after validating user willingness to pay for higher accuracy.