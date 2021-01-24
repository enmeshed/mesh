// Copy of @reach/router's createHistory, modified to allow introspection
// of events that replace (rather than pop or push) items onto the
// history stack, as well as providing the number of items popped from
// the stack in the case of multiple pops.
let canUseDOM = !!(
  typeof window !== "undefined" &&
  window.document &&
  window.document.createElement
);

let getLocation = source => {
  const {
    search,
    hash,
    href,
    origin,
    protocol,
    host,
    hostname,
    port
  } = source.location;
  let { pathname } = source.location;

  if (!pathname && href && canUseDOM) {
    const url = new URL(href);
    pathname = url.pathname;
  }

  const encodedPathname = pathname
  .split("/")
  .map(pathPart => encodeURIComponent(decodeURIComponent(pathPart)))
  .join("/");

  return {
    pathname: encodedPathname,
    search,
    hash,
    href,
    origin,
    protocol,
    host,
    hostname,
    port,
    state: source.history.state,
    key: (source.history.state && source.history.state.key) || "initial"
  };
};

let createHistory = (source, options) => {
  let listeners = [];
  let location = getLocation(source);
  let transitioning = false;
  let resolveTransition = () => {};
  let goTo = -1;

  return {
    get location() {
      return location;
    },

    get transitioning() {
      return transitioning;
    },

    _onTransitionComplete() {
      transitioning = false;
      resolveTransition();
    },

    listen(listener) {
      listeners.push(listener);

      let popstateListener = () => {
        location = getLocation(source);
        const actualGoTo = goTo;
        goTo = -1;
        listener({ location, action: "POP", to: actualGoTo });
      };

      source.addEventListener("popstate", popstateListener);

      return () => {
        source.removeEventListener("popstate", popstateListener);
        listeners = listeners.filter(fn => fn !== listener);
      };
    },

    navigate(to, { state, replace = false } = {}) {
      let action = replace ? "REPLACE" : "PUSH";
      if (typeof to === "number") {
        source.history.go(to);
        action = "GO";
        goTo = to;
      } else {
        state = { ...state, key: Date.now() + "" };
        // try...catch iOS Safari limits to 100 pushState calls
        try {
          if (transitioning || replace) {
            source.history.replaceState(state, null, to);
          } else {
            source.history.pushState(state, null, to);
          }
        } catch (e) {
          source.location[replace ? "replace" : "assign"](to);
        }
      }

      location = getLocation(source);
      transitioning = true;
      let transition = new Promise(res => (resolveTransition = res));
      listeners.forEach(listener => listener({ location, action }));
      return transition;
    }
  };
};

const history = createHistory(window)
const { navigate } = history

export { createHistory, history, navigate }
