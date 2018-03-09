Function Get-RandomPassword {
	Param (
		[int]$length = 10
	)

	$ascii = $NULL
	For ($a = 48; $a -le 122; $a++) {
		$ascii +=,[char][byte]$a
	}

	For ($loop = 1; $loop -le $length; $loop++) {
		$tmpPassword += ($ascii | Get-Random)
	}

	return $tmpPassword
}

Function Add-DTLRAccounts {
	Param (
		[string]$file
	)
}
