Function Get-RandomPassword {
	Param (
		[int]$Length = 10
	)

	$ascii = $NULL
	For ($a = 48; $a -le 122; $a++) {
		$ascii +=,[char][byte]$a
	}

	For ($loop = 1; $loop -le $Length; $loop++) {
		$tmpPassword += ($ascii | Get-Random)
	}

	return $tmpPassword
}

Function Add-DTLRAccounts {
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[ValidatePattern('\.csv$')]
		[string]$File,
		[Parameter()]
		[ValidateSet("User","Store","Service")]
		[string]$AcctType = "User",
		[switch]$Verbose = $false
	)
}
