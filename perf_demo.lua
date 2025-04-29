local Fractional = require("fractional")
local cli_utils = require("cli_utils")
local Frac = Fractional
local DATA_FILE = "stock_prices.tsv"
local NUM_PORTFOLIOS = 20
local TRANSACTION_COUNT = 20000
local TRANSACTION_SEED = 12345
local load_stock_data
load_stock_data = function()
  local file = io.open(DATA_FILE, "r")
  if not file then
    error("Could not find stock price data file. Run stock_data_generator.moon first.")
  end
  local header = file:read("*line")
  local tickers = { }
  for ticker in header:gmatch("[^\t]+") do
    table.insert(tickers, ticker)
  end
  table.remove(tickers, 1)
  local prices = { }
  local days = { }
  for line in file:lines() do
    if line and line ~= "" then
      local values = { }
      local day_data = { }
      local i = 1
      for value in line:gmatch("[^\t]+") do
        if i == 1 then
          day_data.date = value
          table.insert(days, value)
        else
          local ticker = tickers[i - 1]
          day_data[ticker] = tonumber(value)
        end
        i = i + 1
      end
      prices[day_data.date] = day_data
    end
  end
  file:close()
  return {
    tickers = tickers,
    days = days,
    prices = prices
  }
end
local Portfolio
do
  local _class_0
  local _base_0 = {
    buy = function(self, date, ticker, dollars)
      local price_per_share = self.market.prices[date][ticker]
      if not price_per_share then
        return false
      end
      local dollar_amount
      if type(dollars) == "number" then
        dollar_amount = Frac(dollars)
      else
        dollar_amount = dollars
      end
      if dollar_amount > self.cash then
        return false
      end
      local price = Frac(price_per_share)
      local shares = dollar_amount / price
      self.cash = self.cash - dollar_amount
      if self.holdings[ticker] then
        self.holdings[ticker] = self.holdings[ticker] + shares
      else
        self.holdings[ticker] = shares
      end
      table.insert(self.transactions, {
        date = date,
        type = "buy",
        ticker = ticker,
        shares = shares,
        price = price,
        amount = dollar_amount
      })
      return true
    end,
    sell = function(self, date, ticker, dollars_or_all)
      local price_per_share = self.market.prices[date][ticker]
      if not price_per_share then
        return false
      end
      local current_shares = self.holdings[ticker] or Frac(0)
      if current_shares == Frac(0) then
        return false
      end
      local price = Frac(price_per_share)
      local current_value = current_shares * price
      local shares_to_sell = nil
      local dollar_amount = nil
      if dollars_or_all == "all" then
        shares_to_sell = current_shares
        dollar_amount = current_value
      else
        if type(dollars_or_all) == "number" then
          dollar_amount = Frac(dollars_or_all)
        else
          dollar_amount = dollars_or_all
        end
        if dollar_amount > current_value then
          dollar_amount = current_value
        end
        shares_to_sell = dollar_amount / price
      end
      self.cash = self.cash + dollar_amount
      self.holdings[ticker] = current_shares - shares_to_sell
      table.insert(self.transactions, {
        date = date,
        type = "sell",
        ticker = ticker,
        shares = shares_to_sell,
        price = price,
        amount = dollar_amount
      })
      return true
    end,
    calculate_value = function(self, date)
      local start_time = os.clock()
      local total = Frac(self.cash)
      for ticker, shares in pairs(self.holdings) do
        if shares > Frac(0) and self.market.prices[date] and self.market.prices[date][ticker] then
          local price = Frac(self.market.prices[date][ticker])
          local value = shares * price
          self.operation_count = self.operation_count + 1
          total = total + value
          self.operation_count = self.operation_count + 1
        end
      end
      self.daily_value[date] = total
      self.time_to_value = self.time_to_value + (os.clock() - start_time)
      return total
    end,
    calculate_returns = function(self)
      local start_time = os.clock()
      local prev_value = nil
      local prev_date = nil
      for i, date in ipairs(self.market.days) do
        if self.daily_value[date] then
          local current_value = self.daily_value[date]
          if prev_value then
            local daily_change = current_value - prev_value
            self.operation_count = self.operation_count + 1
            self.daily_return[date] = daily_change / prev_value
            self.operation_count = self.operation_count + 1
          else
            self.daily_return[date] = Frac(0)
          end
          local total_change = current_value - self.initial_investment
          self.operation_count = self.operation_count + 1
          self.cumulative_return[date] = total_change / self.initial_investment
          self.operation_count = self.operation_count + 1
          prev_value = current_value
          prev_date = date
        end
      end
      self.time_to_returns = self.time_to_returns + (os.clock() - start_time)
    end,
    calculate_all_values = function(self)
      for _, date in ipairs(self.market.days) do
        self:calculate_value(date)
      end
    end,
    format_large_fraction = function(self, frac, prefix)
      if prefix == nil then
        prefix = "$"
      end
      local num_str = tostring(frac.num)
      local den_str = tostring(frac.den)
      if den_str == "0" then
        return tostring(prefix) .. "Infinity"
      end
      if num_str == "0" then
        return tostring(prefix) .. "0.00"
      end
      local sig_digits = 12
      local num_significant = string.sub(num_str:gsub("^%-", ""), 1, math.min(sig_digits, #num_str))
      local den_significant = string.sub(den_str:gsub("^%-", ""), 1, math.min(sig_digits, #den_str))
      if #num_str < sig_digits then
        num_significant = num_significant .. string.rep("0", sig_digits - #num_str)
      end
      if #den_str < sig_digits then
        den_significant = den_significant .. string.rep("0", sig_digits - #den_str)
      end
      local magnitude = #num_str - #den_str
      local num_val = tonumber(num_significant)
      local den_val = tonumber(den_significant)
      if num_val and den_val and den_val > 0 then
        if magnitude > 6 then
          local base = num_val / den_val
          return string.format(tostring(prefix) .. "%.2f × 10^%d", base, magnitude)
        elseif magnitude < -6 then
          local base = num_val / den_val
          return string.format(tostring(prefix) .. "%.2f × 10^-%d", base, -magnitude)
        else
          local ratio = num_val / den_val
          if magnitude > 0 then
            ratio = ratio * (10 ^ magnitude)
          elseif magnitude < 0 then
            ratio = ratio / (10 ^ -magnitude)
          end
          return string.format(tostring(prefix) .. "%.2f", ratio)
        end
      end
      return frac:format_money()
    end,
    print_summary = function(self)
      print("\nPortfolio Summary: " .. tostring(self.name))
      local formatted_initial = self:format_large_fraction(self.initial_investment)
      print("Initial Investment: " .. tostring(formatted_initial) .. " (" .. tostring(self.initial_investment) .. ")")
      local last_date = self.market.days[#self.market.days]
      if self.daily_value[last_date] then
        local final_value = self.daily_value[last_date]
        local return_pct = self.cumulative_return[last_date] * Frac(100)
        local return_val = return_pct:to_number_for_display()
        local return_formatted = string.format("%.2f%%", return_val)
        local final_formatted = self:format_large_fraction(final_value)
        print("Final Value: " .. tostring(final_formatted) .. " (" .. tostring(return_formatted) .. " return) (" .. tostring(final_value) .. ")")
      end
      print("\nFinal Holdings:")
      for ticker, shares in pairs(self.holdings) do
        if shares > Frac(0) then
          local last_price = self.market.prices[last_date][ticker]
          local value = shares * Frac(last_price)
          local formatted_value = self:format_large_fraction(value)
          local formatted_shares = shares:format("", 5)
          local formatted_price = string.format("%.2f", last_price)
          print("  " .. tostring(ticker) .. ": " .. tostring(formatted_shares) .. " shares @ $" .. tostring(formatted_price) .. " = " .. tostring(formatted_value) .. " (" .. tostring(value) .. ")")
        end
      end
      local formatted_cash = self:format_large_fraction(self.cash)
      print("Cash on hand: " .. tostring(formatted_cash) .. " (" .. tostring(self.cash) .. ")")
      print("\nPerformance metrics:")
      print("  Time spent calculating values: " .. tostring(string.format("%.6f", self.time_to_value)) .. " seconds")
      print("  Time spent calculating returns: " .. tostring(string.format("%.6f", self.time_to_returns)) .. " seconds")
      print("  Total operations: " .. tostring(self.operation_count))
      local ops_per_sec = self.operation_count / (self.time_to_value + self.time_to_returns)
      return print("  Operations per second: " .. tostring(string.format("%.2f", ops_per_sec)))
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, name, initial_cash, market_data)
      if initial_cash == nil then
        initial_cash = Frac(10000, 1)
      end
      self.name = name
      self.cash = initial_cash
      self.holdings = { }
      self.transactions = { }
      self.daily_value = { }
      self.daily_return = { }
      self.cumulative_return = { }
      self.initial_investment = initial_cash
      self.market = market_data
      self.time_to_value = 0
      self.time_to_returns = 0
      self.operation_count = 0
      for _, ticker in ipairs(self.market.tickers) do
        self.holdings[ticker] = Frac(0)
      end
    end,
    __base = _base_0,
    __name = "Portfolio"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Portfolio = _class_0
end
local generate_random_transactions
generate_random_transactions = function(portfolio, num_transactions)
  math.randomseed(TRANSACTION_SEED)
  local transaction_dates = { }
  local max_date_index = math.floor(#portfolio.market.days * 0.8)
  for i = 1, max_date_index do
    table.insert(transaction_dates, portfolio.market.days[i])
  end
  for i = 1, num_transactions do
    local date_idx = math.random(1, #transaction_dates)
    local date = transaction_dates[date_idx]
    local ticker_idx = math.random(1, #portfolio.market.tickers)
    local ticker = portfolio.market.tickers[ticker_idx]
    if math.random() < 0.7 or portfolio.holdings[ticker] == Frac(0) then
      local amount = math.random(100, 5000)
      if portfolio.cash > Frac(amount) and math.random() < 0.8 then
        portfolio:buy(date, ticker, amount)
      end
    else
      if math.random() < 0.3 then
        portfolio:sell(date, ticker, "all")
      else
        local current_value = portfolio.holdings[ticker] * Frac(portfolio.market.prices[date][ticker])
        local max_sell = current_value:to_number()
        if max_sell > 100 then
          local amount = math.random(100, math.min(max_sell, 5000))
          portfolio:sell(date, ticker, amount)
        end
      end
    end
  end
end
print("Portfolio Performance Testing with Fractional Library")
print("====================================================")
print("Loading stock market data...")
if not io.open(DATA_FILE, "r") then
  print("Stock data file not found. Generating synthetic data first...")
  os.execute("moonrun stock_data_generator.moon")
end
local market = load_stock_data()
print("Loaded data for " .. tostring(#market.tickers) .. " stocks over " .. tostring(#market.days) .. " days")
print("\nCreating " .. tostring(NUM_PORTFOLIOS) .. " test portfolios...")
local portfolios = { }
local total_start_time = os.clock()
for i = 1, NUM_PORTFOLIOS do
  local initial_cash = 10000 + math.random(0, 90000)
  local portfolio = Portfolio("Portfolio " .. tostring(i), Frac(initial_cash), market)
  local transactions_per_portfolio = math.floor(TRANSACTION_COUNT / NUM_PORTFOLIOS)
  generate_random_transactions(portfolio, transactions_per_portfolio)
  portfolio:calculate_all_values()
  portfolio:calculate_returns()
  table.insert(portfolios, portfolio)
  print("Portfolio " .. tostring(i) .. " created with " .. tostring(#portfolio.transactions) .. " transactions")
end
local total_time = os.clock() - total_start_time
print("\n====================================================")
print("Performance Summary")
print("====================================================")
print("Total portfolios: " .. tostring(NUM_PORTFOLIOS))
print("Total transactions: " .. tostring(TRANSACTION_COUNT))
print("Total calculation time: " .. tostring(string.format("%.3f", total_time)) .. " seconds")
local total_operations = 0
local total_calc_time = 0
for _, portfolio in ipairs(portfolios) do
  total_operations = total_operations + portfolio.operation_count
  total_calc_time = total_calc_time + (portfolio.time_to_value + portfolio.time_to_returns)
end
local ops_per_second = total_operations / total_calc_time
print("Average operations per second: " .. tostring(string.format("%.2f", ops_per_second)))
print("Total fractional operations: " .. tostring(total_operations))
print("\n====================================================")
print("Individual Portfolio Results")
print("====================================================")
for _, portfolio in ipairs(portfolios) do
  portfolio:print_summary()
end
return print("\nPerformance test complete!")
