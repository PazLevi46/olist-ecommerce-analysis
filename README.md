# Olist E-Commerce Analysis 

In this project, I analyzed the Olist Brazilian E-Commerce dataset, focusing on three key areas: marketplace activity, delivery and logistics, and customer satisfaction. The original dataset is publicly available on Kaggle: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce?resource=download)

**[View the Interactive Power BI Dashboard](https://app.powerbi.com/view?r=eyJrIjoiN2E4YTYwNmEtZGViNy00MzFmLTg4NTQtM2I5ZTc2YzdlNTZjIiwidCI6ImEyYWQ0YzY5LWQ5NjgtNGUxZS1iYWU2LTk3MmYyYjVlYjMxNiJ9&pageName=0b52abb01805b7551ce9)**

### Dataset 
The Olist dataset describes the activity of the Brazilian Olist marketplace between 2016 and 2018. It contains data on roughly 100,000 orders and provides information on orders, customers, products, sellers, payments, reviews, and delivery performance. 

### Analysis Objectives 
I focused the analysis on three main areas: 
1. Marketplace Activity: How did marketplace activity develop over time, and which product categories, sellers, and regions contributed most to marketplace performance? 
2. Delivery & Logistics: How did delivery performance vary across orders and regions, and which factors were most strongly associated with freight costs? 
3. Customer Satisfaction: What was the association between delivery performance and customer satisfaction, and what were the main themes in positive and negative reviews? 

### Tools & Workflow 
* Python (Pandas): Data exploration, cleaning, and preparation 
* SQL (MySQL): Data analysis and business-focused queries 
* Power BI: Data modeling, DAX measures, and interactive dashboard development 

### Data Exploration & Preparation 
After loading the raw data, I performed the following steps: 
1. Explored the structure of the datasets, including data types, missing values, duplicates, and data consistency. 
2. Converted date-related columns from object to datetime data types where appropriate. 
3. Investigated missing and potentially problematic values. Missing values were generally retained rather than removing entire records when the true values could not be reliably inferred. 

## Key Findings 
### 1. Marketplace Activity 
#### Monthly Marketplace Activity 
Marketplace activity increased substantially throughout the analyzed period, with completed orders, items sold, and GMV generally growing together. Average order value and items per order remained relatively stable, suggesting that marketplace growth was primarily driven by increasing transaction volume rather than customers placing larger or higher-value orders. 
#### Product Category Performance 
Product categories differed substantially in their contribution to sales volume and GMV. Health & Beauty performed strongly across both measures, while Watches & Gifts generated high GMV despite lower unit sales due to higher average product prices. In contrast, categories such as Furniture & Decor generated relatively high sales volume but lower GMV, highlighting the importance of considering both volume and product value when evaluating category performance. 
#### Geographic Performance 
Marketplace activity was heavily concentrated in São Paulo, which generated substantially more orders and GMV than any other state. However, São Paulo had the lowest average order value among the leading states, suggesting that its strong marketplace contribution was primarily volume-driven. Other states generated considerably fewer orders but, in several cases, higher average order values. 
### 2. Delivery & Logistics 
#### Overall Delivery Performance 
Delivery performance was generally strong relative to Olist's estimated delivery dates. Approximately 91.9% of delivered orders arrived before the estimated date, while 1.3% arrived on the estimated date and 6.8% arrived late. Early deliveries arrived approximately 13.7 days ahead of the estimate on average, while late deliveries arrived approximately 10.6 days after the estimated date. 
#### Geographic Delivery Performance 
Delivery performance varied considerably across customer locations. Rio de Janeiro stood out among major states, with approximately 12.1% of deliveries arriving late compared with 4.5% in São Paulo. Late deliveries to Rio de Janeiro were also more severely delayed on average, suggesting that customer geography is associated with meaningful differences in delivery performance. 
#### Freight Cost Drivers 
Product weight and volume showed stronger linear relationships with freight cost (Pearson = 0.61 and 0.59, respectively), while shipping distance showed the strongest monotonic relationship (Spearman = 0.64). This suggests that freight pricing is associated with multiple factors and may not increase proportionally with distance alone. 
### 3. Customer Satisfaction 
#### Delivery Performance & Satisfaction 
Customer satisfaction was substantially lower for late deliveries. Orders delivered early received an average review score of 4.29, compared with 4.04 for orders delivered on the estimated date and 2.27 for late deliveries. This indicates a strong association between delivery performance and customer satisfaction. 
#### Severity of Delivery Delays 
Late deliveries were associated with substantially lower customer satisfaction, and review scores generally declined as delays became more severe up to 30 days. Orders delivered 8–30 days late received particularly low average scores of approximately 1.6–1.7. However, this pattern did not continue among delays exceeding 30 days, where the average score increased to 2.06. 
#### Qualitative Review Sample 
A qualitative review of a small random sample of one-star and five-star customer comments provided additional context for the quantitative satisfaction findings. One-star reviews frequently referenced delivery problems, product quality or accuracy issues, missing items, packaging issues, and customer-service concerns. Five-star reviews commonly mentioned high product quality, timely delivery, appropriate packaging, trustworthy sellers, and overall recommendations. 
These observations were exploratory and were not treated as representative estimates of the full review dataset. 

### Dashboard 
#### Marketplace Overview 
<img width="1184" height="667" alt="marketplace_overview" src="https://github.com/user-attachments/assets/02379b2b-128d-4164-ac39-9a79d1438d08" />
Main KPIs, monthly marketplace activity, top 10 product categories by GMV, and geographic distribution of completed orders. 

#### Delivery & Logistics 
<img width="1185" height="668" alt="delivery_logistics" src="https://github.com/user-attachments/assets/73ac9d3f-d094-4a95-aca9-b98d17036d46" />
Delivery performance, including late-delivery severity, geographic differences, and factors associated with freight costs. 

#### Customer Satisfaction 
<img width="1184" height="667" alt="customer_satisfaction" src="https://github.com/user-attachments/assets/ce969bbf-3fe9-4c5c-bf67-83b2f856ab6d" />
Overall review score distribution, satisfaction by delivery performance and delay severity, and major themes from one-star and five-star reviews. 


**[View the Interactive Power BI Dashboard](https://app.powerbi.com/view?r=eyJrIjoiN2E4YTYwNmEtZGViNy00MzFmLTg4NTQtM2I5ZTc2YzdlNTZjIiwidCI6ImEyYWQ0YzY5LWQ5NjgtNGUxZS1iYWU2LTk3MmYyYjVlYjMxNiJ9&pageName=0b52abb01805b7551ce9)**

### Methodology & Limitations 
1. Marketplace performance metrics were calculated using delivered orders only. 
2. Monthly trend analysis focused on January 2017 – August 2018 due to sparse and discontinuous observations in the 2016 portion of the dataset. 
3. Repeat purchasing was measured within a 180-day follow-up window. Only customers with a complete 180-day observation period were included, and subsequent orders placed within 10 minutes of the first order were not considered repeat purchases. 
4. Shipping distance was approximated using representative coordinates for customer and seller zip-code prefixes and calculated using the Haversine formula. Therefore, the resulting distances should be interpreted as estimates rather than exact shipping-route distances. 
5. The qualitative review analysis was based on a random sample of 25 one-star and 25 five-star reviews and was exploratory rather than representative of the full review dataset. 

#### AI Assistance 
AI tools were used throughout the project as a learning and development aid, primarily for concept clarification, debugging support, code review, and feedback on analytical decisions. The analysis, implementation, validation, and interpretation of results were performed and reviewed by me. 

### Repository Structure
```text
olist-ecommerce-analysis/
├── data/
│   ├── README.md
│   ├── orders_dashboard.csv
│   └── sales_dashboard.csv
├── images/
│   ├── customer_satisfaction.png
│   ├── delivery_logistics.png
│   └── marketplace_overview.png
├── notebook/
│   └── olist_data_preparation.ipynb
├── sql analysis/
│   └── olist_analysis.sql
└── README.md
```

 

 

 
