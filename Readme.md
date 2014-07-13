Find polluting test by bisecting your tests.

Install
=======

```Bash
gem install cleanser
```

Usage
=====

```Ruby
# whole test folder
cleanser folder failing_test.rb

# individual files
cleanser other_test.rb failing_test.rb yetanother_test.rb failing_test.rb
```

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/cleanser.png)](https://travis-ci.org/grosser/cleanser)
