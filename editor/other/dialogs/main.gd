extends Control

func activate():
	%message.grab_focus()

	%message.text_submitted.connect(func(t):
		if t == "":
			return

		OS.execute("git", ["add", "."])
		OS.execute("git", ["commit", "-m", t])
		OS.execute("git", ["push"])

		%message.text = ""
	)
