import music;
import std.conv,
	   std.string,
	   std.concurrency,
	   std.stdio;
import dlangui,
	   dlangui.dialogs.filedlg,
	   dlangui.dialogs.dialog;

enum MARGIN = 10;
enum CONTINUE = 3;
enum STOP = 2;
enum CHANGE = 4;

mixin APP_ENTRY_POINT;

private
{
	Window window;
	bool played;
	Tid tid;
}
extern(C) int UIAppMain(string[] args)
{
	Platform.instance.uiLanguage = "en";
	Platform.instance.uiTheme = "theme_default";
	window = Platform.instance.createWindow("yacmp",null,0,300,100);
	window.mainWidget = parseML(q{
		VerticalLayout{
			minWidth:300
			minHeight:100
			TextWidget{
				id: musicName
				text:"File Not Found"
				fontSize:15
				minHeight: 50
			}
			HorizontalLayout{
				Button{
					id: stopButton
					text:"stop"
					minWidth:100
					minHeight:50
				}
				Button{
					id: continueButton
					text:"continue"
					minWidth:100
					minHeight:50
				}
				Button{
					id: changeButton
					text:"select"
					minWidth:100
					minHeight:50
				}
			}
		}
	});
	window.mainWidget.childById!Button("stopButton").enabled = false;
	window.mainWidget.childById!Button("continueButton").enabled = false;

	window.mainWidget.childById!Button("stopButton").click = delegate(Widget src)
		{
			
			window.mainWidget.childById!Button("stopButton").enabled = false;
			window.mainWidget.childById!Button("continueButton").enabled = true;
			stopMusic;
			return true;		
		};
	window.mainWidget.childById!Button("continueButton").click = delegate(Widget src)
		{
			window.mainWidget.childById!Button("stopButton").enabled = true;
			window.mainWidget.childById!Button("continueButton").enabled = false;
			continueMusic;
			return true;
		};
	window.mainWidget.childById!Button("changeButton").click = delegate(Widget src)
		{
			played = true;
			window.mainWidget.childById!Button("stopButton").enabled = true;
			window.mainWidget.childById!Button("continueButton").enabled = false;
			window.mainWidget.childById!Button("changeButton").text = "change";
			changeMusic;
			return true;
		};

	window.show;
	tid = spawn(&yacmp_main);
	return Platform.instance.enterMessageLoop;
}

void continueMusic()
{
	tid.send(CONTINUE);	
}		

void stopMusic()
{
	tid.send(STOP);
}

void changeMusic()
{
	UIString caption = "select file"d;
	uint flg = DialogFlag.Modal;
	auto dialog = new FileDialog(caption,window,null,flg);
	dialog.dialogResult = delegate(Dialog dialog,const Action result)
		{
			if (result.stringParam.length != 0)
			{
				sendChangeSignal(result.stringParam);
				version(Windows)
					auto strings = result.stringParam.split("\\");
				else
					auto strings = result.stringParam.split("/");
				window.mainWidget.childById!TextWidget("musicName").text = strings[$-1].to!dstring;
			}
		};
	dialog.show;
}

void sendChangeSignal(string file)
{
	if (played)
		tid.send(CHANGE);
	else
		played = false;
	tid.send(file);
}
