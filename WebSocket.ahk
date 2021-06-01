class WebSocket
{
	__New(WS_URL)
	{
		static wb
		
		; Create an IE instance
		Gui, +hWndhOld
		Gui, New, +hWndhWnd
		this.hWnd := hWnd
		Gui, Add, ActiveX, vwb x0 y0 w1000 h600, Shell.Explorer
		;~ Gui, Show, w1000 h600
		wb.silent := true
		Gui, %hOld%: Default
		
		; Write an appropriate document
		wb.Navigate("about:<!DOCTYPE html><meta http-equiv='X-UA-Compatible'"
		. "content='IE=edge'><body></body>")
		;~ WB.Navigate("about:blank")
		while (wb.ReadyState < 4)
			sleep, 50
		this.document := wb.document
		IID_IWebBrowserApp := "{0002DF05-0000-0000-C000-000000000046}", IID_IHTMLWindow2 := "{332C4427-26CB-11D0-B483-00C04FD90119}"
		this.win := ComObject(9,ComObjQuery(wb, IID_IHTMLWindow2, IID_IHTMLWindow2),1)
		
		; Add our handlers to the JavaScript namespace
		this.win.ahk_savews := this._SaveWS.Bind(this)
		this.win.ahk_event := this._Event.Bind(this)
		this.win.ahk_ws_url := WS_URL
		this.win.execScript("ws = new WebSocket(ahk_ws_url);`n"
		. "ws.onopen = function(event){ ahk_event('Open', event); };`n"
		. "ws.onclose = function(event){ ahk_event('Close', event); };`n"
		. "ws.onerror = function(event){ ahk_event('Error', event); };`n"
		. "ws.onmessage = function(event){ ahk_event('Message', event); };")
		this.ws := this.win.ws
	}
	
	; Called by the JS in response to WS events
	_Event(EventName, Event)
	{
		this["On" EventName](Event)
	}
	
	; Sends data through the WebSocket
	Send(Data)
	{
		this.ws.send(Data)
	}
	
	; Closes the WebSocket connection
	Close(Code:=1000, Reason:="")
	{
		this.ws.close(Code, Reason)
	}
	
	; Closes and deletes the WebSocket, removing
	; references so the class can be garbage collected
	Disconnect()
	{
		if this.hWnd
		{
			this.Close()
			Gui, % this.hWnd ": Destroy"
			this.hWnd := False
		}
	}
}
