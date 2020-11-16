Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'nps/:company_name', to: 'tweet_sentiment#find_and_score'
  post 'complete', to: 'completion#complete'
end
