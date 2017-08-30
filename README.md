# Misty's engine

I wonder what media will look like in 5 years. I'm hoping that machine learning get's involved. Some aggregate of all the stories written by humans determines what percentage chance any given "fact" in an article might be accurate based on sources. AI based ranking of accuracy and potential bias will help bring more of the things we are afraid to look at out into the light. I think that is an amazing thing to be able to witness.

Let it begin with me...


## Setup

Install gem'y gems...

```
# bundle install
```

## Gather an article

Create a news key:

```
# rake mk_event_key["Joel Osteen Houston Flood 2017"]
I, [2017-08-30T11:12:51.645017 #24756]  INFO -- : EventKey: b8304989c784f6ad39d9ef42aae1de92485dd515
```
Now grab an article:

```
# rake grab:article["b8304989c784f6ad39d9ef42aae1de92485dd515, http://www.huffingtonpost.com/entry/joel-osteen-lakewood-church-houston-harvey_us_59a6ac7fe4b084581a148cef?section=us_us-news"]
```

```
# cat data/articles/b8304989c784f6ad39d9ef42aae1de92485dd515/45e54c3d08c59456f9d3ce1d2ed1215567cd7070.json |jq '.'
```

This will output the json data for the article.
