
import QtQml 2.2
import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtGraphicalEffects 1.0
import QtWebEngine 1.7

import "../components"
import "../components/dialogs"

Page {
	id: webviewPage
	width: parent.width
	height: parent.height

	header:Item {
		height: 0
		visible: false
	}
	
	Component {
		id: pickerComponent
		PickerDialog {}
	}
	


	Item {
		id:webContainer
		anchors {
			top:parent.top
			left:parent.left
			right:parent.right
			bottom:bottomControls.top
		}
		MainWebView {
			id:webView
			url: helperFunctions.getInstanceURL()
			filePicker: pickerComponent
			confirmDialog: ConfirmDialog {}
			alertDialog: AlertDialog {}
			promptDialog:PromptDialog {}
			onLoadProgressChanged: {
				progressBar.value = loadProgress
			}
			settings.showScrollBars:false
		}
// 		InnerShadow {
// 			color: theme.palette.normal.progress
// 			radius: 10
// 			samples: 30
// 			anchors.fill:webView
// 			source:webView
// 			fast:true
// 			horizontalOffset: 0
// 			verticalOffset: -2
// 			spread:0.5
// 			visible:webView.loading
// 			z:2
// 		}
	}


	Rectangle {
		id:loadingPage
		anchors.fill: parent
		visible: !webviewPage.currentView().visible
		color: theme.palette.normal.background
		

		property bool hasLoadError: ( progressBar.value == 100 && webviewPage.currentView().lastStatus == WebEngineLoadRequest.LoadFailedStatus )

		onVisibleChanged: if(visible) {
			reloadButton.visible = false;
		}
		
		Timer {
			interval: 5000
			running: visible
			onTriggered: {
				reloadButton.visible = true;
			}
		}
		
		
		Label {
			id: progressLabel
			color: theme.palette.normal.backgroundText
			text: i18n.tr('Loading ') + settings.instance
			anchors.centerIn: parent
			textSize: Label.XLarge
		}

		ProgressBar {
			id: progressBar
			value: 0
			minimumValue: 0
			maximumValue: 100
			anchors.top: progressLabel.bottom
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.topMargin: 10
			StyleHints {
				foregroundColor: loadingPage.hasLoadError ? 
									theme.palette.normal.negative :
									theme.palette.normal.progress
			}
		}
		
		Button {
			id:reloadButton
			visible: loadingPage.hasLoadError
			anchors.top: progressBar.bottom
			anchors.topMargin: units.gu(2)
			anchors.horizontalCenter: parent.horizontalCenter
			color: loadingPage.hasLoadError ? theme.palette.normal.negative : UbuntuColors.blue
			width:height + units.gu(1)
			iconName:"reload"
			onClicked: {
				webviewPage.currentView().reload()
			}
		}

		Button {
			anchors.bottom: parent.bottom
			anchors.bottomMargin: height
			anchors.horizontalCenter: parent.horizontalCenter
			color: UbuntuColors.red
			text: "Choose another Instance"
			onClicked: {
				settings.instance = undefined
				mainStack.clear ()
				mainStack.push (Qt.resolvedUrl("./InstancePicker.qml"))
			}
		}
	}
	
	Rectangle {
		color: theme.pallete.highlighted.selectedText
		anchors.bottom:instancBottomEdge.status !== BottomEdge.Committed ? bottomControls.top : instancBottomEdge.top
		anchors.bottomMargin: 1
		width: parent.width * webviewPage.currentView().loadProgress / 100
		height: units.gu(0.1)
		visible: webviewPage.currentView().visible && webviewPage.currentView().loading
		z:3
		layer.enabled: true
		layer.effect:DropShadow {
		radius: 10
		samples: 30
		fast:true
		horizontalOffset: 0
		verticalOffset: -2
		spread:0.5
			 color:theme.palette.highlighted.progress
		}
	}

	BottomEdgeControlsHeader {
		id:bottomControls
		z:2
		anchors.bottom: parent.bottom
		anchors.bottomMargin : visible ? 0 : -height
		visible: webviewPage.currentView().visible && ( !settings.hideBottomControls || !webviewPage.isOnDiaspora() );
		trailingSlots: !webviewPage.isOnDiaspora() ? 4 : 3
		
		leadingActionBar {
			numberOfSlots:6
			visible:webviewPage.isOnDiaspora()
			actions: [
				Action {
					text:i18n.tr("Add Post")
					iconName:"edit"
					onTriggered:instancBottomEdge.commit();
				},			
				Action {
					text:i18n.tr("Messages")
					iconName:"messages"
					onTriggered:webviewPage.currentView().url = helperFunctions.getInstanceURL() +"/conversations";
				},			
				Action {
					text:i18n.tr("Notifications")
					iconName:"notification"
					onTriggered:webviewPage.currentView().url = helperFunctions.getInstanceURL() +"/notifications";
				},
				Action {
					enabled:false
				},
				Action {
					text:i18n.tr("Stream")
					iconSource:"../../assets/diaspora-asterisk.png"
					onTriggered:webviewPage.currentView().goHome();
				}
			]
		}
	}

	BottomEdge {
		id: instancBottomEdge
		visible: webviewPage.currentView().visible  && webviewPage.isOnDiaspora()
		height:units.gu(45)
		hint.iconName: "go-up"
		hint.visible:visible
		preloadContent: false
		contentComponent: Component { 
			AddPost {
				anchors.fill:instancBottomEdge
				height:instancBottomEdge.height
				width:instancBottomEdge.width
				filePickerComponent:pickerComponent
			}
		}

		onCommitStarted: contentItem.resetURL();
	}
	
	//========================== Functions =======================
	function currentView() {
		return  settings.incognitoMode ? webViewIncogito : webView;
	}
	
	function  isOnDiaspora() {
		return (currentView().url.toString().indexOf(settings.instance) !== -1)
	}
	
	function isLoggedin() {
		var loginPage = helperFunctions.getInstanceURL() + "/users/sign_in"
		return currentView().url != loginPage;
	}

}
