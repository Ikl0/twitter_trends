require 'json'

def split_tweet_line(line)
  line.split("\t")
end

def get_tweet_text(line_arr)
  data_arr = line_arr.map(&:split)
  data_arr[3]
end

def get_tweet_coord(line)
  arr = []
  data_arr = line.map(&:split)
  latitude = data_arr[0][0].delete('[').delete(',').to_f
  longitude = data_arr[0][1].delete(']').to_f
  arr << latitude << longitude
end

def split_sentiment_data(info_line)
  info_line.chop.split(',')
end

sentiment_data = []
File.readlines('sentiments/sentiments').each do |info_line|
  sentiment_data << split_sentiment_data(info_line)
end
sentiment_hash = sentiment_data.to_h

coord_weight_of_all_tweets_array = []
File.readlines('tweets/football_tweets2014').each do |info_line|
  arr_element = []
  arr_str = get_tweet_text(split_tweet_line(info_line))
  sum = 0
  sentiment_hash.each do |key, value|
     sum += value.to_f if arr_str.include?(key)
  end
  sum = sum / arr_str.length
  # get_tweet_coord(split_tweet_line(info_line))
  arr_element << get_tweet_coord(split_tweet_line(info_line)) << sum.round(3)
  coord_weight_of_all_tweets_array << arr_element
end


file = File.read('states/states')
sentiment_hash = JSON.parse(file)

def is_in_polygon?(polygon, testing_point)
  result = false
  j = polygon.size - 1
  0.upto(polygon.size-1) do |i|
    if polygon[i][1] < testing_point[0] && polygon[j][1] >= testing_point[0] || polygon[j][1] < testing_point[0] && polygon[i][1] >= testing_point[0]
      if polygon[i][0] + (testing_point[0] - polygon[i][1]) / (polygon[j][1] - polygon[i][1]) * (polygon[j][0] - polygon[i][0]) < testing_point[1]
        result = !result
      end
    end
    j = i
  end
  result
end


state_weight_hash = {}
coord_weight_of_all_tweets_array.each do |point|
  sentiment_hash.each do |_key, value|
    value.each do |el|
      result = nil
      if value.size > 1
        el.each do |polygon|
          result = is_in_polygon?(polygon, point[0])
        end
      else
        result = is_in_polygon?(el, point[0])
      end
      if result
        if state_weight_hash.include?(_key)
          state_weight_hash[_key] += point[1]
        else
          state_weight_hash[_key] = point[1]
        end
      end
    end
  end
end

p state_weight_hash.sort{|a,b| b[1] <=> a[1]}

  File.open('results/result_football_tweets2014.txt', 'w') do |f|
    f.write("#{state_weight_hash.sort{|a,b| b[1] <=> a[1]}}")
    f.close
  end