import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import TopicMap from "discourse/components/topic-map";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";

export default class StickyMap extends Component {
  @service currentUser;
  @service site;
  @service stickyMapState;

  @action
  showSummary() {
    return this.args.outletArgs.model.postStream.showSummary();
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

  @action
  updateCurrentPost() {
    return this.stickyMapState.updateCurrentPost(
      this.args.outletArgs.model.currentPost
    );
  }

  <template>
    {{#if this.stickyMapState.stickyMapVisible}}
      <div
        class="sticky-topic-map"
        {{didUpdate
          this.updateCurrentPost
          this.args.outletArgs.model.currentPost
        }}
      >

        <div class="topic-map">
          <TopicMap
            @model={{@outletArgs.model}}
            @postStream={{@outletArgs.model.postStream}}
            @cancelFilter={{this.cancelFilter}}
            @showTopReplies={{this.showTopReplies}}
            @showSummary={{this.showSummary}}
            @topicDetails={{@outletArgs.model.details}}
            @collapseSummary={{this.collapseSummary}}
          />
        </div>
      </div>
    {{/if}}
  </template>
}
