linear_model = function(train, test) {
  num_forecasts = nrow(test)
  train[is.na(train)] = 0
  
  # Forecast using linear regression model per store
  for (j in 2:ncol(train)) {
    s = ts(train[, j], frequency = 52)
    model = tslm(s ~ trend + season)
    fc = forecast(model, h = num_forecasts)
    test[, j] = as.numeric(fc$mean)
  }
  return(test)
}

shift = function(dept_preds) {
  # This function circularly shift a fraction of the sales from weeks 48 through 
  # 52 into the next week if the sales of holiday weeks are 10% greater than  
  # the baseline (i.e. non-holiday weeks)
  shift = 1
  threshold = 1.1
  idx = week(dept_preds$Date) %in% 48:52
  holiday = dept_preds[idx, 2:46]
  baseline = mean(rowMeans(holiday[c(1,5), ], na.rm = TRUE))
  surge = mean(rowMeans(holiday[2:4, ], na.rm=TRUE))
  holiday[is.na(holiday)] = 0
  if(is.finite(surge/baseline) & surge/baseline > threshold){
    shifted.sales = ((7-shift)/7) * holiday
    shifted.sales[2:5, ] = shifted.sales[2:5, ] + (shift/7) * holiday[1:4, ]
    shifted.sales[1, ] = holiday[1, ]
    dept_preds[idx, 2:46] = shifted.sales
  }
  return(dept_preds)
}

update_forecast = function(test_month, dept_preds, dept) {
  # Convert forecast with shape (num_test_dates, num_store) to a dataframe 
  # with Date, Store, Weekly_Price columns
  dept_preds = gather(dept_preds, Store, Weekly_Price, -Date, convert = TRUE)
  
  # Obtain the index where test_month$Dept equals dept
  pred.d.idx = test_month$Dept == dept
  
  # Rearrange dept_preds to match the order found in test_month
  pred.d = test_month[pred.d.idx, c('Store', 'Date')] %>% 
    left_join(dept_preds, by = c('Store', 'Date'))
  
  test_month$Weekly_Pred[pred.d.idx] = pred.d$Weekly_Price
  
  return(test_month)
}

mypredict = function() {
  ##### Create train and test time-series ######
  if (t > 1) {
    # Append the previous periods test data to the current training data
    train <<- train %>% add_row(new_train)
  }
  
  # Filter test dataframe for the month that do need predictions
  # Backtesting starts from March 2011
  start_date = ymd("2011-03-01") %m+% months(2 * (t - 1))
  end_date = ymd("2011-05-01") %m+% months(2 * (t - 1))
  test_month = test %>% filter(Date >= start_date & Date < end_date) %>% 
    add_column(Weekly_Pred = NA)
  
  # Get the dates for test dataframe
  test_dates = unique(test_month$Date)
  num_test_dates = length(test_dates)
  
  # No need to consider stores that do not need prediction
  all_stores = unique(test_month$Store)
  num_stores = length(all_stores)
  
  # No need to consider departments that do not need prediction
  test_depts = unique(test_month$Dept)
  
  # Create the structure of test dataframe with 
  # the shape (num_test_dates, num_stores)
  test_frame = data.frame(
    Date = rep(test_dates, num_stores),
    Store = rep(all_stores, each = num_test_dates)
  )
  
  # Create the structure of training dataframe with 
  # the shape (num_train_dates, num_stores)
  train_dates = unique(train$Date)
  num_train_dates = length(train_dates)
  train_frame = data.frame(
    Date = rep(train_dates, num_stores),
    Store = rep(all_stores, each = num_train_dates)
  )
  
  ##### Perform individual forecasts for each department ######
  for (dept in test_depts) {
    # Extract the current department from the training data
    train_dept_ts = train %>% filter(Dept == dept) %>% 
      select(Store, Date, Weekly_Sales)
    
    # Reformat train_dept_ts so that it has a shape (num_train_dates, num_stores)
    # Each column is a weekly time-series for a store's department
    train_dept_ts = train_frame %>% 
      left_join(train_dept_ts, by = c("Date", "Store")) %>% 
      spread(Store, Weekly_Sales)
    
    # Create a similar dataframe to hold the forecast on the dates in the 
    # testing window
    test_dept_ts = test_frame %>% mutate(Weekly_Sales = 0) %>% 
      spread(Store, Weekly_Sales)
    
    # Model fitting/forecasting
    f_linear = linear_model(train_dept_ts, test_dept_ts)
    
    # Post-processing
    if (t == 5) f_linear = shift(f_linear)
    test_month = update_forecast(test_month, f_linear, dept)
  }
  test_month = test_month %>% select(-IsHoliday)
  return(test_month)
}