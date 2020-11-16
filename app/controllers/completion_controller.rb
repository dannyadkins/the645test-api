require 'json'
require 'net/http'
class CompletionController < ApplicationController
    def complete
        key = Rails.application.credentials[:gpt_key]
        prefix = "You're speaking with a startup investor about your technology company. They're interested in growth, metrics, and your business plan. They'll ask questions and give feedback.\n\n"
        logger.debug "REQUEST:"
        request_body = request.body.read
        logger.debug request_body
        input_text = JSON.parse(request_body)['text']

        uri = URI('https://api.openai.com/v1/engines/davinci/completions')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri, {'Content-Type' => 'application/json', 'Authorization'=>'Bearer ' + key})
        request.body = {temperature: 0.5,
                        max_tokens: 64,
                        top_p: 1,
                        frequency_penalty: 0.48,
                        prompt:prefix + input_text,
                        stop: ["You:"]
                    }.to_json
        logger.debug "REQUEST:"
        logger.debug request.body
        response = http.request(request)
        body = JSON.parse(response.body) # e.g {answer: 'because it was there'}
        logger.debug "RESPONSE:"
        logger.debug body['choices'][0]['text']
        render :json =>  {text: body['choices'][0]['text']}
    end    
end