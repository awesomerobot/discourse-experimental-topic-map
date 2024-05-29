import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.20.0", (api) => {
  const site = api.container.lookup("service:site");
  //  workaround for now
  // enables user cards in the mobile users modal
  // by allowing usercards in all mobile modals
  if (site.mobileView) {
    api.addCardClickListenerSelector(".modal-container");
  }
});
