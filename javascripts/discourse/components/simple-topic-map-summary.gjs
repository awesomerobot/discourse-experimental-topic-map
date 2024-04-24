import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { inject as service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { eq, gt } from "truth-helpers";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import DButton from "discourse/components/d-button";
import RelativeDate from "discourse/components/relative-date";
import TopicParticipants from "discourse/components/topic-map/topic-participants";
import avatar from "discourse/helpers/bound-avatar-template";
import number from "discourse/helpers/number";
import replaceEmoji from "discourse/helpers/replace-emoji";
import slice from "discourse/helpers/slice";
import { ajax } from "discourse/lib/ajax";
import dIcon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";
import { avatarImg } from "discourse-common/lib/avatar-utils";
import and from "truth-helpers/helpers/and";
import lt from "truth-helpers/helpers/lt";
import not from "truth-helpers/helpers/not";

const TRUNCATED_LINKS_LIMIT = 5;

export default class SimpleTopicMapSummary extends Component {
  @service stickyMapState;

  @tracked isLoading = false;
  @tracked mostLikedPosts = [];

  get linksCount() {
    return this.args.topicDetails.links?.length ?? 0;
  }

  get createdByUsername() {
    return this.args.topicDetails.created_by?.username;
  }

  get lastPosterUsername() {
    return this.args.topicDetails.last_poster?.username;
  }

  get toggleMapButton() {
    return {
      title: this.args.collapsed
        ? "topic.expand_details"
        : "topic.collapse_details",
      icon: this.args.collapsed ? "chevron-down" : "chevron-up",
      ariaExpanded: this.args.collapsed ? "false" : "true",
      ariaControls: "topic-map-expanded__aria-controls",
      action: this.args.toggleMap,
    };
  }

  get shouldShowParticipants() {
    return (
      this.args.collapsed &&
      this.args.topic.posts_count > 2 &&
      this.args.topicDetails.participants &&
      this.args.topicDetails.participants.length > 0
    );
  }

  get createdByAvatar() {
    return htmlSafe(
      avatarImg({
        avatarTemplate: this.args.topicDetails.created_by?.avatar_template,
        size: "tiny",
        title:
          this.args.topicDetails.created_by?.name ||
          this.args.topicDetails.created_by?.username,
      })
    );
  }

  get lastPostAvatar() {
    return htmlSafe(
      avatarImg({
        avatarTemplate: this.args.topicDetails.last_poster?.avatar_template,
        size: "tiny",
        title:
          this.args.topicDetails.last_poster?.name ||
          this.args.topicDetails.last_poster?.username,
      })
    );
  }

  @action
  updateTab(tab) {
    return this.stickyMapState.updateCurrentTab(tab);
  }

  @action
  fetchMostLiked() {
    this.loading = true;
    const filter = `/search.json?q=" " topic%3A${this.args.topic.id} order%3Alikes`;

    ajax(filter)
      .then((data) => {
        data.posts.sort((a, b) => b.like_count - a.like_count);

        this.mostLikedPosts = data.posts.slice(0, 5);
      })
      .catch((error) => {
        // eslint-disable-next-line no-console
        console.error("Error fetching posts:", error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  <template>
    <ul>
      <li class="created-at">
        <h4 role="presentation">{{i18n "created_lowercase"}}</h4>
        <div class="topic-map-post created-at">
          <a
            class="trigger-user-card"
            data-user-card={{this.createdByUsername}}
            title={{this.createdByUsername}}
            aria-hidden="true"
          />
          {{this.createdByAvatar}}
          <RelativeDate @date={{@topic.created_at}} />
        </div>
      </li>
      <li class="last-reply">
        <a href={{@topic.lastPostUrl}}>
          <h4 role="presentation">{{i18n "last_reply_lowercase"}}</h4>
          <div class="topic-map-post last-reply">
            <a
              class="trigger-user-card"
              data-user-card={{this.lastPosterUsername}}
              title={{this.lastPosterUsername}}
              aria-hidden="true"
            />
            {{this.lastPostAvatar}}
            <RelativeDate @date={{@topic.last_posted_at}} />
          </div>
        </a>
      </li>

      <li class="replies">
        {{number @topic.replyCount noTitle="true"}}
        <h4 role="presentation">{{i18n
            "replies_lowercase"
            count=@topic.replyCount
          }}</h4>
      </li>
      <li class="secondary views">
        {{number @topic.views noTitle="true" class=@topic.viewsHeat}}
        <h4 role="presentation">{{i18n
            "views_lowercase"
            count=@topic.views
          }}</h4>
      </li>

      {{#if (gt @topic.like_count 0)}}
        <li
          class="secondary likes
            {{if (eq this.stickyMapState.currentTab 'likes') '--active'}}"
          {{on "click" (fn this.updateTab "likes")}}
        >
          {{number @topic.like_count noTitle="true"}}
          <h4 role="presentation">{{i18n
              "likes_lowercase"
              count=@topic.like_count
            }}</h4>
        </li>
      {{/if}}
      {{#if (gt this.linksCount 0)}}
        <li
          class="secondary links
            {{if (eq this.stickyMapState.currentTab 'links') '--active'}}"
          {{on "click" (fn this.updateTab "links")}}
        >
          {{number this.linksCount noTitle="true"}}
          <h4 role="presentation">{{i18n
              "links_lowercase"
              count=this.linksCount
            }}</h4>
        </li>
      {{/if}}
      {{#if (gt @topic.participant_count 0)}}
        <li
          class="secondary users
            {{if (eq this.stickyMapState.currentTab 'users') '--active'}}"
          {{on "click" (fn this.updateTab "users")}}
        >
          {{number @topic.participant_count noTitle="true"}}
          <h4 role="presentation">{{i18n
              "users_lowercase"
              count=@topic.participant_count
            }}</h4>
        </li>
      {{/if}}

      {{#if this.shouldShowParticipants}}
        <li class="avatars">
          <TopicParticipants
            @participants={{slice 0 4 @topicDetails.participants}}
            @userFilters={{@userFilters}}
          />
        </li>
      {{/if}}
    </ul>

    {{#if (eq this.stickyMapState.currentTab "users")}}
      <section class="avatars">
        <TopicParticipants
          @title={{i18n "topic_map.participants_title"}}
          @userFilters={{@userFilters}}
          @participants={{@topicDetails.participants}}
        />
      </section>
    {{/if}}

    {{#if (eq this.stickyMapState.currentTab "links")}}
      <section class="links">
        <h3>{{i18n "topic_map.links_title"}}</h3>
        <table class="topic-links">
          <tbody>
            {{#each this.linksToShow as |link|}}
              <tr>
                <td>
                  <span
                    class="badge badge-notification clicks"
                    title={{i18n "topic_map.clicks" count=link.clicks}}
                  >
                    {{link.clicks}}
                  </span>
                </td>
                <td>
                  <TopicMapLink
                    @attachment={{link.attachment}}
                    @title={{link.title}}
                    @rootDomain={{link.root_domain}}
                    @url={{link.url}}
                    @userId={{link.user_id}}
                  />
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
        {{#if
          (and
            (not this.allLinksShown)
            (lt TRUNCATED_LINKS_LIMIT this.topicLinks.length)
          )
        }}
          <div class="link-summary">
            <span>
              <DButton
                @action={{this.showAllLinks}}
                @title="topic_map.links_shown"
                @icon="chevron-down"
                class="btn-flat"
              />
            </span>
          </div>
        {{/if}}
      </section>
    {{/if}}

    {{#if (eq this.stickyMapState.currentTab "likes")}}
      <section class="likes" {{didInsert this.fetchMostLiked}}>
        <h3>Most liked posts</h3>

        <ConditionalLoadingSpinner @condition={{this.loading}}>
          <ul>
            {{#each this.mostLikedPosts as |post|}}
              <li>
                <a
                  href="/t/{{this.args.topic.slug}}/{{this.args.topic.id}}/{{post.post_number}}"
                >
                  <span class="like-section__user">
                    {{avatar
                      post.avatar_template
                      "tiny"
                      (hash title=post.username)
                    }}
                    {{post.username}}
                  </span>

                  <span class="like-section__likes">
                    {{post.like_count}}
                    {{dIcon "heart"}}</span>
                  <p>
                    {{htmlSafe post.blurb}}
                  </p>
                </a>
              </li>
            {{/each}}
          </ul>
        </ConditionalLoadingSpinner>

      </section>
    {{/if}}
  </template>
}

class TopicMapLink extends Component {
  get linkClasses() {
    return this.args.attachment
      ? "topic-link track-link attachment"
      : "topic-link track-link";
  }

  get truncatedContent() {
    const truncateLength = 85;
    const content = this.args.title || this.args.url;
    return content.length > truncateLength
      ? `${content.slice(0, truncateLength).trim()}...`
      : content;
  }

  <template>
    <a
      class={{this.linkClasses}}
      href={{@url}}
      title={{@url}}
      data-user-id={{@userId}}
      data-ignore-post-id="true"
      target="_blank"
      rel="nofollow ugc noopener noreferrer"
    >
      {{#if @title}}
        {{replaceEmoji this.truncatedContent}}
      {{else}}
        {{this.truncatedContent}}
      {{/if}}
    </a>
    {{#if (and @title @rootDomain)}}
      <span class="domain">
        {{@rootDomain}}
      </span>
    {{/if}}
  </template>
}
