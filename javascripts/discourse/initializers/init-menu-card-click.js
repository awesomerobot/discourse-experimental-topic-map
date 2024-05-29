import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.20.0", (api) => {
  const site = api.container.lookup("service:site");
  // enables user cards in the users menu

  if (document.querySelector(".topic-map.--simplified")) {
    api.addCardClickListenerSelector(".topic-map.--simplified");
  }

  if (site.mobileView) {
    // workaround for now
    api.addCardClickListenerSelector(".modal-container");
  }
});
