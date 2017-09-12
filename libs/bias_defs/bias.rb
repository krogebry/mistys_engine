
is_described_as :dislike do
  words [ 'deranged', 'idiot', 'incompetent', 'unstable', 'insane', 'bigot', 'wrong', 'feckless', 'bored' ]
end

is_described_as :like do
  words [ 'good', 'patriotic', 'strong', 'competent' ]
end

bias "Trump is evil" do
  subject :person do
    is_described_as [ "Trump", "Donald Trump", "president" ]
    is_described_with :dislike
  end
end

bias "Hillary is evil" do
  subject :person do
    is_described_as [ "Hillary Clinton", "Mrs. Clinton", "Clinton", "Hillary" ]
    is_described_with :like
  end
end

#bias "Fox is evil" do
#end

bias "Hillary is good" do
  #subject :event do
    #is_described_as [ "Bengahzi" ]
    #is_mentioned
  #end

  #subject :location do
    #is_described_as [ "Bengahzi" ]
    #is_mentioned
  #end

  subject :person do
    is_described_as [ "Hillary", "Mrs. Clinton", "Clinton" ]
    is_described_with :like
  end
end
