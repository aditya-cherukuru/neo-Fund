const groqClient = require('../utils/groqClient');
const logger = require('../utils/logger');

class AIInvestmentForecastService {
  static async generateForecast(params) {
    try {
      const {
        amount,
        duration,
        durationType = 'years',
        investmentType,
        riskAppetite,
        expectedReturn,
        currency = 'USD',
        userProfile = {}
      } = params;

      // Create a comprehensive prompt for AI analysis
      const prompt = `Analyze the following investment scenario and provide a detailed forecast:

Investment Details:
- Amount: ${amount} ${currency}
- Duration: ${duration} ${durationType}
- Investment Type: ${investmentType}
- Risk Appetite: ${riskAppetite}
- Expected Return: ${expectedReturn ? (expectedReturn * 100).toFixed(2) + '%' : 'Not specified'}

User Profile: ${JSON.stringify(userProfile)}

Please provide a comprehensive investment forecast including:
1. Projected returns under different market scenarios (bull, bear, neutral)
2. Risk assessment and volatility estimates
3. Recommended investment strategy
4. Key factors that could impact performance
5. Timeline milestones and expected portfolio value at different points
6. Risk mitigation strategies

Format the response as a structured JSON object with the following structure:
{
  "scenarios": {
    "bull": { "projectedValue": number, "annualReturn": number, "confidence": string },
    "neutral": { "projectedValue": number, "annualReturn": number, "confidence": string },
    "bear": { "projectedValue": number, "annualReturn": number, "confidence": string }
  },
  "riskAssessment": {
    "volatility": string,
    "riskLevel": string,
    "keyRisks": [string],
    "mitigationStrategies": [string]
  },
  "recommendations": {
    "strategy": string,
    "diversification": string,
    "timeline": string
  },
  "milestones": [
    { "year": number, "projectedValue": number, "notes": string }
  ],
  "factors": [string],
  "summary": string
}`;

      // Get AI response from Groq
      const response = await groqClient.chat.completions.create({
        messages: [
          {
            role: "system",
            content: "You are an expert financial advisor and investment analyst. Provide accurate, well-reasoned investment forecasts based on the given parameters. Always respond with valid JSON format."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        model: "mixtral-8x7b-32768",
        temperature: 0.3,
        max_tokens: 4000
      });

      const aiResponse = response.choices[0]?.message?.content;
      
      if (!aiResponse) {
        throw new Error('No response received from AI service');
      }

      // Try to parse the JSON response
      let forecastData;
      try {
        // Extract JSON from the response (in case there's additional text)
        const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          forecastData = JSON.parse(jsonMatch[0]);
        } else {
          forecastData = JSON.parse(aiResponse);
        }
      } catch (parseError) {
        logger.error('Failed to parse AI response as JSON:', parseError);
        // Fallback to a structured response
        forecastData = this.generateFallbackForecast(params);
      }

      // Add metadata to the forecast
      forecastData.metadata = {
        generatedAt: new Date().toISOString(),
        inputParameters: params,
        aiModel: 'mixtral-8x7b-32768',
        confidence: 'AI-generated'
      };

      return forecastData;

    } catch (error) {
      logger.error('Error generating AI investment forecast:', error);
      
      // Return fallback forecast if AI service fails
      return this.generateFallbackForecast(params);
    }
  }

  static generateFallbackForecast(params) {
    const { amount, duration, durationType, investmentType, riskAppetite, expectedReturn } = params;
    
    // Simple fallback calculation based on expected return
    const annualReturn = expectedReturn || 0.07; // Default to 7% if not specified
    const years = durationType === 'months' ? duration / 12 : duration;
    
    const projectedValue = amount * Math.pow(1 + annualReturn, years);
    
    return {
      scenarios: {
        bull: {
          projectedValue: projectedValue * 1.2,
          annualReturn: annualReturn * 1.3,
          confidence: "High"
        },
        neutral: {
          projectedValue: projectedValue,
          annualReturn: annualReturn,
          confidence: "Medium"
        },
        bear: {
          projectedValue: projectedValue * 0.8,
          annualReturn: annualReturn * 0.7,
          confidence: "Low"
        }
      },
      riskAssessment: {
        volatility: "Moderate",
        riskLevel: riskAppetite || "Medium",
        keyRisks: ["Market volatility", "Economic downturns", "Interest rate changes"],
        mitigationStrategies: ["Diversification", "Regular rebalancing", "Long-term perspective"]
      },
      recommendations: {
        strategy: `Invest in ${investmentType} with ${riskAppetite} risk tolerance`,
        diversification: "Consider spreading investments across different asset classes",
        timeline: `${duration} ${durationType} investment horizon`
      },
      milestones: [
        { year: 1, projectedValue: amount * (1 + annualReturn), notes: "First year milestone" },
        { year: Math.floor(years / 2), projectedValue: amount * Math.pow(1 + annualReturn, years / 2), notes: "Mid-term milestone" },
        { year: years, projectedValue: projectedValue, notes: "Target completion" }
      ],
      factors: ["Market performance", "Economic conditions", "Investment strategy"],
      summary: `Based on ${annualReturn * 100}% annual return, your ${amount} investment could grow to approximately ${projectedValue.toFixed(2)} over ${years} years.`,
      metadata: {
        generatedAt: new Date().toISOString(),
        inputParameters: params,
        aiModel: "fallback",
        confidence: "Fallback calculation"
      }
    };
  }
}

module.exports = AIInvestmentForecastService; 