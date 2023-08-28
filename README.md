# Gitcoin Passport plugin for Discourse

### Goal

The Gitcoin Passport plugin implements sybil resistance for Discourse forums.
It allows you to connect a Gitcoin passport to your Discourse account.

Out of the box, Discourse uses so called trust level groups to prevent spam and to make sure that people have the access rights to read, post and reply in the forum. These groups are then used to protect categories and restrict and allow all kinds of functionality.

Someone with trust level 2 on Discourse is automatically a member of the groups `trust_level_0`, `trust_level_1`,  and `trust_level_2`.

The Gitcoin Passport plugin builds upon the existing group authorization mechanism by adding its own trust level equivalent groups: the **unique humanity score** groups.

A user with unique humanity score X will be a member of all unique_humanity_Y groups where Y is less or equal to X. Because the unique humanity score can be anything between 0 and 100, the forum administrator gets to decide which levels are being used to allow or restrict functionality. 

### Configuration

* Install the SIWE plugin and configure a WalletConnect project ID
* Install the Gitcoin Passport plugin and configure the Gitcoin Passport Scorer ID and API Key.
* Configure the groups you want to have by entering a sequence of numbers separated by comma's in the `gitcoin passport group levels` setting. For instance 0,5,20 will create groups `unique_humanity_0`, `unique_humanity_5` and `unique_humanity_20`.
* Configure the badge levels for a bronze, silver and gold badge.

### Protecting Categories

Say you want to have a category that requires score 40 to create a topic and score 20 to reply. 

* Make sure that 20 and 40 are in the `gitcoin passport group levels` setting so there will be groups `unique_humanity_20` and `unique_humanity_40`
* Go to the category you want to protect
* Remove Reply and Create for Everybody
* Add the groups and their respective permissions

![category settings](https://raw.githubusercontent.com/communiteq/discourse-gitcoin-passport/98b7dba221b4ef9fa4c631f0e754977f56ed2223/img/passport1.png)

In this example:
* A user without a Gitcoin passport will be able to read the topics
* A user with a unique humanity score of 15 will be able to read the topics
* A user with a unique humanity score of 25 will be able to read and reply to topics
* A user with a unique humanity score of 41 will be able to read, reply to and create topics.

### User journey

Once installed, configured and enabled, the plugin will prompt existing users to connect their Ethereum wallet.

![connect wallet](https://raw.githubusercontent.com/communiteq/discourse-gitcoin-passport/98b7dba221b4ef9fa4c631f0e754977f56ed2223/img/passport2.png)

Pressing the Connect button will kick off the SIWE authentication flow.

Once the wallet has been connected, the banner will change and ask people to configure and connect their Passport

![connect passport](https://raw.githubusercontent.com/communiteq/discourse-gitcoin-passport/98b7dba221b4ef9fa4c631f0e754977f56ed2223/img/passport3.png)

On success, the current passport score will be shown to the user

![score popup](https://raw.githubusercontent.com/communiteq/discourse-gitcoin-passport/98b7dba221b4ef9fa4c631f0e754977f56ed2223/img/passport4.png)

The score will also be shown in the admin panel for the user

![score admin](https://raw.githubusercontent.com/communiteq/discourse-gitcoin-passport/98b7dba221b4ef9fa4c631f0e754977f56ed2223/img/passport5.png)


and the user preferences

![score user prefs](https://raw.githubusercontent.com/communiteq/discourse-gitcoin-passport/98b7dba221b4ef9fa4c631f0e754977f56ed2223/img/passport6.png)

and on the user card

![score user card](https://raw.githubusercontent.com/communiteq/discourse-gitcoin-passport/98b7dba221b4ef9fa4c631f0e754977f56ed2223/img/passport7.png)

and of course the user will be member of the groups they're entitled to

![group members](https://raw.githubusercontent.com/communiteq/discourse-gitcoin-passport/98b7dba221b4ef9fa4c631f0e754977f56ed2223/img/passport8.png)

and get the corresponding badges

![badges](https://raw.githubusercontent.com/communiteq/discourse-gitcoin-passport/98b7dba221b4ef9fa4c631f0e754977f56ed2223/img/passport1.png)


The score for each user will be refreshed twice per day.

### Settings

* `gitcoin_passport_enabled`: Enable Gitcoin Passport plugin.
* `gitcoin_passport_api_key`: Gitcoin Passport API key.
* `gitcoin_passport_scorer_id`: Gitcoin Passport Scorer ID.
* `gitcoin_passport_group_levels`: The unique humanity scores that should have a group.
* `gitcoin_passport_show_on_usercard`: Show unique humanity score on user card.
* `gitcoin_passport_ethereum_node_url`: Public Ethereum node to use for name resolution.
* `gitcoin_passport_badge_group`: Name for the badge group.
* `gitcoin_passport_badge_bronze_score`: The minimum unique humanity score to get a bronze badge.
* `gitcoin_passport_badge_silver_score`: The minimum unique humanity score to get a silver badge.
* `gitcoin_passport_badge_gold_score`: The minimum unique humanity score to get a gold badge.

### Demo

The plugin is live at https://gitcoinpassport.demo.communiteq.com/ Anyone can sign up freely and play around there.

If any of you want to play around with it from an admin POV, just let us know your account name 
and we'll grant you admin permissions.

### Source

Last but not least the source is available at https://github.com/communiteq/discourse-gitcoin-passport/

