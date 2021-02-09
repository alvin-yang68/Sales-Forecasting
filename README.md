# Sales forecasting of Walmart stores

Link to the Kaggle competition: https://www.kaggle.com/c/walmart-recruiting-store-sales-forecasting/overview

Historical sales data for 45 Walmart stores located in different regions were provided. Each
store contains many departments. The goal is to predict the future weekly sales for each
department in each store based on the historical data.

The training file provides the weekly sales data for various stores and departments from 2010-
02 to 2011-02. For each fold, the goal is to predict sales data for 8 weeks in the future (i.e. the
forecast horizon is 2 months) based on sales data available up to then. This is done through
calling the mypredict() function. The actual sales data corresponding with the current
forecast horizon is then added into the training set for the next fold.

## The `mypredict()` function

When the mypredict() function is called, it will first extend the training set with two
additional months of sales data. The first fold is an exception since it would only use data from
2010-02 to 2011-02.

The function will then perform individual forecast for each department in the test set. At each
iteration, both the test matrix and training matrix used for the forecasting are derived. The test
matrix has a structure where the rows are dates corresponding to the forecast horizon of the
current fold, and columns representing the stores associated with the department to be
forecasted. The training matrix has a similar structure except the rows correspond to the dates
from the training set available to the current fold. The restructuring is required in order to use
the forecasting functions available from the forecast package. Next, the linear_model()
function is called by passing in the training matrix and an empty test matrix. It will then output
the test matrix with the predicted sale prices.

In fold 5, the sale prices are shifted in order to account for the slight shift of the Christmas
shopping season from 2010 to 2011. After the predicted sale prices for every store and
department have been obtained, it will transform the data back to the original format of the test
matrix before returning it.

## Linear regression model

In the linear_model() function, the tslm command from the forecast package is applied
over each column of the training matrix. This is the same as fitting a linear regression model
on the time series of a given store, and then the sales of this store for the next two months are
forecasted using the fitted model. This is done for every store of a given department.

A linear regression model is selected because it can learn time series patterns through feature
engineering. Additionally, it has some advantages over naïve or seasonal naïve models because
it is able to learn both the trend and seasonality of the time series data.
Although there is not much trend in the Walmart time series data since there are only up to two
years of training data when forecasting for sales price in 2012, it might still be useful to include.
Trend is modelled by including a degrees of freedom associated with time in the linear model.
For instance, a linear regression model that considers only the trend is given by $y_t=\beta_0 + \beta_1 t + \epsilon_t$ (where $t$ denotes the time and $y_t$ the observed value at $t$).

In contrast, the Walmart time series data exhibits a strong seasonality. Seasonality can be
modelled by using seasonal dummy variables in the linear regression model. The categorical
variable modelling the seasonality has 52 levels corresponding to the 52 weeks in a year.
Hence, there are 52 dummy variables in the model. Note that when forecasting the sales price
for the weeks of 2011, the training data contains just one season (i.e. 2010) so the linear
regression model is equivalent to the seasonal naïve model. This is because the linear regression
model will just memorize the value from the last season for that week and predict the same
value as that. On the other hand, forecasting the sales price for the weeks of 2012 will use data
from the previous two seasons (i.e. 2010 and 2011).

## Shifting

Fold 5 has a high WMAE because it contains two holiday weeks and therefore receives higher
weights in WMAE. The high WMAE for fold 5 is due to a slight shift of the Christmas shopping
season from 2010 to 2011.

The forecast model assumes the time series has a frequency of 52 weeks per year. For the most
part this worked well since the data is short. Super Bowl is always on a Sunday and
Thanksgiving is always on a Thursday, so those events have a fixed relationship to the week
boundaries. Labor Day is not in the test data, so it is irrelevant here. However, Christmas occurs
on a fixed date so its day of the week changes.

In 2010, Christmas occurs on a Saturday (where each week ends on Friday). That causes all of
its associated sales to fall into the week before. However, in 2011, it occurs on a Sunday, so
there is one pre-Christmas shopping day in week 52.

In order to account for this, a post-forecast adjustment was made for fold 5 (weeks 46 to 52).
If the average sales for weeks 49, 50 and 51 of a given department were at least 10% higher
than for weeks 48 and 52, then circularly shift a fraction of the sales from weeks 48 through 52
into the next week (and from 52 back to 48). Since the tslm model is fitted based on training
data from 2010 when predicting the holidays of 2011, the sale for a given week is circularly
shifted by 1/7 to the next week.

## Results

The weighted mean absolute error (WMAE) of the time series linear model (tslm) was
evaluated for each of the ten folds. The results are summarized below,

| Fold 1  | Fold 2  | Fold 3  | Fold 4  | Fold 5  | Fold 6  | Fold 7  | Fold 8  | Fold 9  | Fold 10 |
|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|
| 2042    | 1440    | 1435    | 1597    | 2029    | 1674    | 1719    | 1421    | 1431    | 1447    |
