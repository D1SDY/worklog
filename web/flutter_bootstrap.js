{{flutter_js}}
{{flutter_build_config}}

// A home-screen PWA reopens from the browser's HTTP cache, which on GitHub
// Pages may hold the previous index.html for up to 10 minutes. The app
// revalidates index.html on launch and whenever it returns to the foreground,
// and reloads when a newer build has been deployed. A reload that did not
// deliver the new build (the CDN answered from its cache, the network
// dropped) is retried once that cache window has passed.
const WORKLOG_RELOAD_RETRY_MS = 10 * 60 * 1000;

function worklogBuildToReloadFor(runningVersion, deployedIndexHtml, lastAttempt, now) {
  const deployed = deployedIndexHtml.match(/buildVersion = "(\d+)"/);
  if (!deployed || deployed[1] === runningVersion) {
    return null;
  }
  if (
    lastAttempt &&
    lastAttempt.version === deployed[1] &&
    now - lastAttempt.at < WORKLOG_RELOAD_RETRY_MS
  ) {
    return null;
  }
  return deployed[1];
}

if (typeof window !== 'undefined') {
  (function () {
    const buildVersion = {{flutter_service_worker_version}};
    const reloadKey = 'worklog.reloadAttempt';
    let checkInFlight = false;
    window.worklogBuildVersion = buildVersion;

    for (const build of _flutter.buildConfig.builds) {
      if (build.mainJsPath) {
        build.mainJsPath += '?v=' + buildVersion;
      }
    }

    _flutter.loader.load({
      onEntrypointLoaded: async function (engineInitializer) {
        const appRunner = await engineInitializer.initializeEngine({
          hostElement: document.getElementById('app'),
        });
        await appRunner.runApp();
      },
    });

    async function reloadIfNewBuildDeployed() {
      if (checkInFlight) {
        return;
      }
      checkInFlight = true;
      try {
        const response = await fetch(document.baseURI, { cache: 'no-cache' });
        const target = worklogBuildToReloadFor(
          buildVersion,
          await response.text(),
          JSON.parse(sessionStorage.getItem(reloadKey) || 'null'),
          Date.now(),
        );
        if (target !== null) {
          sessionStorage.setItem(
            reloadKey,
            JSON.stringify({ version: target, at: Date.now() }),
          );
          window.location.reload();
        }
      } catch (error) {
        console.warn('Worklog: could not check for a newer build.', error);
      } finally {
        checkInFlight = false;
      }
    }

    reloadIfNewBuildDeployed();
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') {
        reloadIfNewBuildDeployed();
      }
    });
  })();
}
