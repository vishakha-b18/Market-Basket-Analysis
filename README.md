# Market-Basket-Analysis
Market Basket Analysis for an organization to identify the most frequently selling products  in order to devise cross-selling marketing strategies.


## Frequent Itemset Mining:</br>
Frequent patterns are patterns (such as item sets, subsequences, or substructures) that appear in a data set frequently. For example, a set of items, such as milk and bread, that appear frequently together in a transaction data set is a frequent itemset. Finding such frequent patterns plays an essential role in mining associations, correlations, and many other interesting relationships among data. A typical example of frequent itemset mining is Market Basket Analysis. This process analyzes customer buying habits by finding associations between the different items that customers place in their “shopping baskets”. Discovery of such associations and correlations amongst products in a customer’s basket is known by the term Association Rule Mining.

The frequent association rules that can be mined from the baskets of products on the left are: </br>
• If A is bought, B is also bought { A } => { B } </br>
• If B is bought, A is also bought { B } => { A } </br>
• If A & B are bought together, C is bought { A, B } => C } </br>

I used the Apriori Algorithm to create the association rules for this analysis. The metrics of Support, Confidence & Lift are used to devise the best rules. </br>

## How to choose a good rule? </br>
• The threshold of support & confidence is generally considered on the higher side. The larger the support & confidence, the more popular and stronger the association rule is, and
thus higher would be the chances of success of any action that is taken with this rule. </br>

• Lift must be used in conjunction with Confidence to judge the credibility of an association rule. Sometimes the confidence of the association rule might have a spurious
adjustment that might lead to a superficially increased value. To avoid such errors, it is important that only those rules are considered where not only the confidence is high, but also the value of lift is above 1. </br>

• Rules with larger value of lift should be preferred, given that the confidence of the rule is above the threshold. </br>
