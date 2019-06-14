# RubyTapas rom-rb companion scripts

These scripts accompany my 3-part [RubyTapas][rubytapas] series on [rom-rb][rom-rb]:

1. [Getting started with rom-rb][ep1] — [episode_1.rb][ep1_script]
2. [Writing changes with rom-rb][ep2] — [episode_2.rb][ep2_script]
3. [Building queries with rom-rb][ep3] — [episode_3.rb][ep3_script]

[rubytapas]: https://www.rubytapas.com/
[rom-rb]: https://rom-rb.org/

[ep1]: https://www.rubytapas.com/2018/12/03/getting-started-with-rom-rb/
[ep2]: https://www.rubytapas.com/2018/12/11/writing-changes-with-rom-rb/
[ep3]: https://www.rubytapas.com/2018/12/19/building-queries-with-rom-rb/

[ep1_script]: /episode_1.rb
[ep2_script]: /episode_2.rb
[ep3_script]: /episode_3.rb

## Setup

First, ensure you have postgres running, then create the `rubytapas_rom` database.

Run `bundle` to install the gems.

Then run e.g. `bundle exec episode_1.rb` to run the companion script for the episode.

Some notes about these scripts:

- They're designed to be run repeatedly, so with each invocation they drop and re-create their respective database tables, then fill them with the sample data.
- They're not intended to output anything. If you want to play around, drop some `puts` lines or debugger statements wherever you like, or give the fancy [Seeing Is Believing][seeing_is_believing] gem a go, along with an editor integration.

Enjoy!

[seeing_is_believing]: https://github.com/JoshCheek/seeing_is_believing
