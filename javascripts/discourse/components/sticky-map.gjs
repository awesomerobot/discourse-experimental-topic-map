import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { inject as service } from "@ember/service";
import { bind } from "discourse-common/utils/decorators";
import SimpleTopicMapSummary from "../components/simple-topic-map-summary";

export default class StickyMap extends Component {
  @service currentUser;
  @service stickyMapState;

  observer = null;

  get topicDetails() {
    return this.args.outletArgs.model.get("details");
  }

  get shouldStick() {
    return (
      this.args.outletArgs.model.posts_count > 3 &&
      this.stickyMapState.stickyMap
    );
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

  @action
  observeStickyMap() {
    // detects when the element is sticky
    const el = document.querySelector(".sticky-topic-map");

    this.observer = new IntersectionObserver(
      ([entry]) => {
        const isSticky = entry.intersectionRatio < 1;
        entry.target.classList.toggle("is-sticky", isSticky);
      },
      {
        threshold: [1],
        rootMargin: "0px 0px -1px 0px",
      }
    );

    this.observer.observe(el);
  }

  willDestroy() {
    super.willDestroy();
    this.observer.disconnect();
  }

  <template>
    {{#unless @outletArgs.model.postStream.loadingFilter}}
      <div
        class="sticky-topic-map {{if this.shouldStick '--sticky'}}"
        {{didInsert this.observeStickyMap}}
      >
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
  </template>
}
