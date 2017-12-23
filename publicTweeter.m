function out = publicTweeter(TwitterCreds,user,num,NYTkey)
%PUBLICTWEETER  tweet analysis and news coverage
%   out = publicTweeter(TwitterCreds,user,num,NYTkey) returns a
%   description of public figure's most common capitalized word from num
%   recent tweets, as well as the headline of the most recent NYT piece 
%   about user. Limit num <= 200
%   
%   As implied, only works on public figures, specifically figures whose
%   names on Twitter are in the form XX Lastname, where XX can be anything
%
%   Tweets retrieved via <a href="matlab:web('https://www.mathworks.com/matlabcentral/fileexchange/34837-twitty')">twitty</a>
%
%   See twitty documentation for format of TwitterCreds (Twitter uses OAuth)
%   NYTkey is char of NYT API key

warning('off','all'); % some cases throw warning
tw = twitty(TwitterCreds); % twitty works using OOP
fprintf('Grabbing %d tweets from %s...',num,user) % large num can slow, provide status
data = jsondecode(tw.userTimeline('screen_name',user,'count',num,'exclude_replies','true','include_rts','false')); % no replies or retweets
name = data{1}.user.name; % actual full name
spaces = strfind(name,' ');
name = name(spaces(end) + 1:end); % only last name for NYT search
disp(' Done.');

tweets = [];
for i = 1:length(data)
    tweet = data{i}.text;
    stop = strfind(tweet,'https://t.co'); % get rid of links
    if ~isempty(stop)
        tweet = tweet(1:stop - 2);
    end
    stop2 = strfind(tweet,'\u2026'); % long tweets end
    if ~isempty(stop2)
        tweet = tweet(1:stop2 - 1);
    end
    tweets = [tweets, {tweet}];
end
names = [];

for i = 1:length(tweets)
    tweet = tweets{i};
    tweet = erase(tweet,'The'); % problematic sentence-starter
    [first,last] = regexp(tweet,'([A-Z])\w{2,}'); % capitalized, >2 chars
    for j = 1:length(first)
        names = [names, {tweet(first(j):last(j))}];
    end
end
[uniques,~,string_map] = unique(names,'stable');

top = uniques(mode(string_map));
top = top{1};

figure
wordcloud(categorical(names));
title(sprintf('Wordcloud of %s''s most recent %d tweets',user,num))

inds = count(names,top); % double array of 1 and 0
inds(inds == 0) = [];

nyt = webread(sprintf('http://api.nytimes.com/svc/search/v2/articlesearch.json?apikey=%s&fq=headline:("%s")',NYTkey,name));
out = sprintf('%s''s favorite recent topic on Twitter was "%s" appearing %d times. The NYT''s latest headline on them was "%s."',name,top,length(inds),nyt.response.docs{1}.headline.main);
end