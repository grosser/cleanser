Find polluting test by bisecting your tests.

Install
=======

```Bash
gem install cleanser
```

or standalone

```Bash
curl https://rubinjam.herokuapp.com/pack/cleanser > cleanser && chmod +x cleanser
```

Usage
=====

```Bash
# whole test folder
cleanser folder folder/failing_test.rb

Running: bundle exec ruby -r./folder/failing_test.rb -e ''
Status: Success
Running: bundle exec ruby -r./folder/a_test.rb -r./folder/failing_test.rb -r./folder/b_test.rb -e ''
Status: Failure
Running: bundle exec ruby -r./folder/failing_test.rb -r./folder/b_test.rb -e ''
Status: Failure
Fails when folder/b_test.rb.rb, folder/failing_test.rb are run together

# individual files
cleanser other_test.rb failing_test.rb yetanother_test.rb failing_test.rb

# rspec
cleanser other_spec.rb failing_spec.rb yetanother_spec.rb failing_spec.rb --rspec
```

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/cleanser.png)](https://travis-ci.org/grosser/cleanser)
