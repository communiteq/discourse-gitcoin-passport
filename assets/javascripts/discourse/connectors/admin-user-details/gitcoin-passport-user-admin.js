import Component from "@glimmer/component";

export default class GitcoinPassportUserAdmin extends Component {

  get passportStatus() {
    const i = this.args.outletArgs.model.gitcoin_passport_status;
    return I18n.t(`gitcoin_passport_plugin.status_${i}`) || "unknown";
  }

  get showUHScore() {
    return this.args.outletArgs.model.gitcoin_passport_status > 2;
  }

  get uniqueHumanityScore() {
    return this.args.outletArgs.model.unique_humanity_score;
  }
}
