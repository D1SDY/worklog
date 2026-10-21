{{flutter_js}}
{{flutter_build_config}}

(function () {
  const buildVersion = {{flutter_service_worker_version}};
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

  // A home-screen PWA reopens from the browser's HTTP cache, which on GitHub
  // Pages may hold the previous index.html for up to 10 minutes. Revalidate
  // it on launch and whenever the app returns to the foreground, and reload
  // once a newer build has been deployed.
  async function reloadIfNewBuildDeployed() {
    try {
      const response = await fetch(document.baseURI, { cache: 'no-cache' });
      const deployed = (await response.text())
        .match(/buildVersion = "(\d+)"/);
      if (!deployed || deployed[1] === buildVersion) {
        return;
      }
      const reloadKey = 'worklog.reloadedFor';
      if (sessionStorage.getItem(reloadKey) === deployed[1]) {
        return;
      }
      sessionStorage.setItem(reloadKey, deployed[1]);
      window.location.reload();
    } catch (error) {
      console.warn('Worklog: could not check for a newer build.', error);
    }
  }

  reloadIfNewBuildDeployed();
  document.addEventListener('visibilitychange', function () {
    if (document.visibilityState === 'visible') {
      reloadIfNewBuildDeployed();
    }
  });
})();
