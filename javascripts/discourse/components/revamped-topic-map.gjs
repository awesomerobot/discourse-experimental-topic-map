import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { bind } from "discourse-common/utils/decorators";
import SimpleTopicMapSummary from "../components/simple-topic-map-summary";

export default class RevampedTopicMap extends Component {
  @service currentUser;
  @tracked isOP = this.args.outletArgs.isOP ? true : false;

  get topicDetails() {
    return this.args.outletArgs.model.get("details");
  }

  get shouldShow() {
    if (this.args.outletArgs.model.archetype === "private_message") {
      return;
    }

    if (this.isOP) {
      return true;
    } else if (!this.isOP && this.args.outletArgs.model.posts_count > 10) {
      return true;
    }
  }

  @bind
  showSummary() {
    return this.args.outletArgs.model.postStream.showSummary(this.currentUser);
  }

  @action
  showTopReplies() {
    return this.args.outletArgs.model.postStream.showTopReplies();
  }

  @action
  collapseSummary() {
    return this.args.outletArgs.model.postStream.collapseSummary();
  }

  @action
  cancelFilter() {
    return this.args.outletArgs.model.postStream.cancelFilter();
  }

  <template>
    {{#if this.shouldShow}}
      {{#unless @outletArgs.model.postStream.loadingFilter}}
        <div class="revamped-topic-map">
          <div class="topic-map --simplified">
            <div class="map">
              <SimpleTopicMapSummary
                @topic={{@outletArgs.model}}
                @topicDetails={{this.topicDetails}}
                @collapsed={{true}}
                @showSummary={{this.showSummary}}
                @collapseSummary={{this.collapseSummary}}
              />
            </div>
          </div>
        </div>
      {{/unless}}
    {{/if}}
  </template>
}
