local cli_utils = require("cli_utils")
cli_utils.seed_rng()
local NUM_STOCKS = 50
local DAYS = 365
local START_YEAR = 2020
local OUTPUT_FILE = "stock_prices.tsv"
local create_stock
create_stock = function(ticker, bias)
  return {
    ticker = ticker,
    price = 10 + math.random(90),
    volatility = 0.01 + math.random() * 0.04,
    bias = bias
  }
end
local generate_stocks
generate_stocks = function()
  local stocks = { }
  local tickers = {
    "AAPL",
    "MSFT",
    "GOOG",
    "AMZN",
    "META",
    "NFLX",
    "TSLA",
    "NVDA",
    "CSCO",
    "INTC",
    "ADBE",
    "PYPL",
    "CMCSA",
    "PEP",
    "COST",
    "TMUS",
    "SBUX",
    "QCOM",
    "TXN",
    "CHTR",
    "AVGO",
    "GILD",
    "MDLZ",
    "FISV"
  }
  for i = 1, math.min(NUM_STOCKS, #tickers) do
    local bias = math.random() < 0.7 and math.random() * 0.003 or -math.random() * 0.001
    table.insert(stocks, create_stock(tickers[i], bias))
  end
  if NUM_STOCKS > #tickers then
    for i = #tickers + 1, NUM_STOCKS do
      local ticker = string.char(65 + math.random(0, 25)) .. string.char(65 + math.random(0, 25)) .. string.char(65 + math.random(0, 25)) .. string.char(65 + math.random(0, 25))
      local bias = math.random() < 0.5 and math.random() * 0.002 or -math.random() * 0.002
      table.insert(stocks, create_stock(ticker, bias))
    end
  end
  return stocks
end
local get_date_string
get_date_string = function(day_offset)
  local base = os.time({
    year = START_YEAR,
    month = 1,
    day = 1
  })
  local date = os.date("*t", base + day_offset * 86400)
  return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end
local simulate_price_movement
simulate_price_movement = function(stocks)
  local prices = { }
  for day = 0, DAYS - 1 do
    local date = get_date_string(day)
    local daily_prices = {
      date = date
    }
    for _, stock in ipairs(stocks) do
      if day == 0 then
        daily_prices[stock.ticker] = stock.price
      else
        local prev_price = prices[day][stock.ticker]
        local change = prev_price * stock.volatility * (2 * math.random() - 1) + prev_price * stock.bias
        local new_price = prev_price + change
        new_price = math.max(new_price, 1.0)
        if math.random() < 0.003 then
          if math.random() < 0.5 then
            new_price = new_price * (1 + math.random() * 0.15)
          else
            new_price = new_price * (1 - math.random() * 0.12)
          end
        end
        daily_prices[stock.ticker] = new_price
      end
    end
    table.insert(prices, daily_prices)
  end
  return prices
end
local write_to_tsv
write_to_tsv = function(prices)
  local file = io.open(OUTPUT_FILE, "w")
  if not file then
    error("Could not open output file for writing")
  end
  local header = {
    "Date"
  }
  for ticker, _ in pairs(prices[1]) do
    if ticker ~= "date" then
      table.insert(header, ticker)
    end
  end
  file:write(table.concat(header, "\t") .. "\n")
  for _, day_data in ipairs(prices) do
    local row = {
      day_data.date
    }
    for _, ticker in ipairs(header) do
      if ticker ~= "Date" then
        local price = string.format("%.2f", day_data[ticker])
        table.insert(row, price)
      end
    end
    file:write(table.concat(row, "\t") .. "\n")
  end
  file:close()
  print("Generated " .. tostring(#prices) .. " days of price data for " .. tostring(#header - 1) .. " stocks")
  return print("Output written to " .. tostring(OUTPUT_FILE))
end
print("Generating synthetic stock price data...")
local stocks = generate_stocks()
local prices = simulate_price_movement(stocks)
write_to_tsv(prices)
return print("Done!")
