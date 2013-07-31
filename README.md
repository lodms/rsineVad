rsineVad
========

1. Build rsineVad from source\n
    1.1. Clone rsineVad using : git clone https://github.com/lodms/rsineVad.git 
         (= ${rsineVadRoot} )
    1.2. Copy ${rsineVadRoot}/vad to ${virtuosoInstallationRoot} (ie. /usr/local/virtuoso-opensource).
         This is necessary because the following virtuoso procedure currently ignores the resource_base_uri parameter.
    1.3. Start isql (cd into ${virtuosoInstallationRoot} and enter ./bin/isql and hiter enter)
    1.4. Paste the following command to the isql prompt replacing the path variables:
         DB.DBA.VAD_PACK('${rsineVadRoot}/wp5rsine.xml', '.', '${virtuosoInstallationRoot}/share/virtuoso/vad/wp5.vad');
         and hit enter.
    1.5. Start the virtuoso server
    1.6. Open virtuoso's conductor in a browser and login.
    1.7. From the main menu choose "System Admin". From the resulting submenu choose "Packages"
    1.8. "rsine" should already be in the list. Click "install".

2. Administration
    2.1. Settings
         To view settings open up ${virtuosoServer}:${virtuosoPort}/rsine/settings in a browser.
         You can change the host and port of the RSine server.      
