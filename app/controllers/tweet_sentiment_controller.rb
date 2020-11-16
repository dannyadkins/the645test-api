require 'json'
require 'typhoeus'
require 'net/http'

class TweetSentimentController < ApplicationController

    ## Given a company name, find the tweets that contain that and
    ## score their sentiment. Twitter API v2 and Google NL API.
    def find_and_score
        company_name = URI.decode_www_form(params['company_name'])[0][0]
        logger.debug company_name
        logger.debug "Searching tweets for " + company_name
        tweets = twitter_api(company_name)
        logger.debug tweets
        classifications = []

        # tweets.each do |tweet|
        #     sentiment = get_sentiment(tweet['text'])
            # classifications.append({id: tweet['id'], score: sentiment})
        # end
        sentiments = get_sentiment_concurrent(tweets) 
        logger.info("Got sentiments")
        sentiments.each do |item|
            classifications.append({id: item[1]['id'], score: JSON.parse(item[0].response.body)['documentSentiment']['score'], text: item[1]['text']})
        end 
        logger.debug classifications
        render :json => classifications
    end    

    private
    def get_sentiment(tweet)
        uri = URI('https://language.googleapis.com/v1/documents:analyzeSentiment?key=' + APP_CONFIG[:gcloud_key])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri, {'Content-Type' => 'application/json'})

        request.body = {document:{type:"PLAIN_TEXT",content:tweet},encodingType: "UTF8"}.to_json # SOME JSON DATA e.g {msg: 'Why'}.to_json
        response = http.request(request)
        body = JSON.parse(response.body) # e.g {answer: 'because it was there'}
        logger.debug body
        return body['documentSentiment']['score']
    end

    private
    def get_sentiment_concurrent(tweets)
        endpoint = 'https://language.googleapis.com/v1/documents:analyzeSentiment?key=' + APP_CONFIG[:gcloud_key]
        hydra = Typhoeus::Hydra.hydra
        tweet_reqs = []
        tweets.each do |tweet|
            tweet_req = Typhoeus::Request.new(endpoint, method: :post, headers: {'Content-Type' => 'application/json'}, body: {document:{type:"PLAIN_TEXT",content:tweet['text']},encodingType: "UTF8"}.to_json)
            hydra.queue tweet_req
            tweet_reqs.append([tweet_req, tweet])
        end
        hydra.run
        logger.debug "Google response: "
        logger.debug tweet_reqs[0][0].response
        tweet_json = tweet_reqs[0][0].response.body

        return tweet_reqs
    end
    
    private 
    def twitter_api(company_name)
        logger.debug "Twitter API called"

        query = company_name

        query_params = {
            "query": query, # Required
            "max_results": 20,
            "tweet.fields": "id,created_at,text",
            "user.fields": "username"
        }
        options = {
            method: 'get',
            headers: {
            "User-Agent": "v2RecentSearchRuby",
            "Authorization": "Bearer " + APP_CONFIG[:twitter_key]
            },
            params: query_params
        }
        request = Typhoeus::Request.new("https://api.twitter.com/2/tweets/search/recent", options)
        response = request.run
        return JSON.parse(response.body)['data']
    end
end
