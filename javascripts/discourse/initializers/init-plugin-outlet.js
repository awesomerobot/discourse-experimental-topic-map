import { apiInitializer } from "discourse/lib/api";
import RevampedTopicMap from "../components/revamped-topic-map";

export default apiInitializer("1.14.0", (api) => {
  api.renderInOutlet("topic-area-bottom", RevampedTopicMap);
});
