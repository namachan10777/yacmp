import music;
import std.conv,
	   std.string,
	   std.concurrency;
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

	auto stopButton = createButton;
	stopButton.text = "stop";
	stopButton.enabled = false;
	auto continueButton = createButton;
	continueButton.text = "continue";
	continueButton.enabled = false;
	auto changeButton = createButton;
	changeButton.text = "change";
	auto musicName = new TextWidget;
	musicName.fontSize = 15;
	musicName.text = "file not found";
	musicName.minHeight = 100;

	stopButton.addOnClickListener(delegate(Widget src){
				stopButton.enabled = false;
				continueButton.enabled = true;
				stopMusic();
				return true;
			});
	continueButton.addOnClickListener(delegate(Widget src){
				continueButton.enabled = false;
				stopButton.enabled = true;
				continueMusic();
				stopMusic();
				return true;
			});


	changeButton.addOnClickListener(delegate(Widget src){
				continueButton.enabled = false;
				stopButton.enabled = true;
				changeMusic(musicName);
				return true;
			});
					
	auto layout = new VerticalLayout;
	layout.maxHeight = 100;
	layout.maxWidth = 300;
	auto buttonLayout = new HorizontalLayout;
	buttonLayout.addChild(stopButton);
	buttonLayout.addChild(continueButton);
	buttonLayout.addChild(changeButton);
	layout.addChild(musicName);
	layout.addChild(buttonLayout);
	window.mainWidget = layout;
	window.show;
	tid = spawn(&yacmp_main);
	return Platform.instance.enterMessageLoop;
}

Button createButton()
{
	auto button = new Button;
	button.fontSize = 15;
	button.minWidth = 100;
	button.minHeight = 50;
 	return button;
}

void continueMusic()
{
	tid.send(CONTINUE);	
}		

void stopMusic()
{
	tid.send(STOP);
}

void changeMusic(TextWidget text)
{
	UIString caption = "select file"d;
	uint flg = DialogFlag.Modal;
	string file;
	auto dialog = new FileDialog(caption,window,null,flg);
	dialog.dialogResult = delegate(Dialog dialog,const Action result)
		{
			sendChangeSignal(result.stringParam);
			version(Windows)
			{
				auto strings = result.stringParam.split("\\");
				text.text = strings[$-1].to!dstring;
			}
			else
			{
				auto strings = result.stringParam.split("/");
				text.text = strings[$-1].to!dstring;
			}
		};
	dialog.show;
}

void sendChangeSignal(string file)
{
	if (played)
	{
		tid.send(CHANGE);
		tid.send(file);
	}
	else
	{

		tid.send(file);
		played = false;
	}
}
