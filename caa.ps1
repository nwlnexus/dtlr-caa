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
		[string]$File
	)

	$Accts = Import-Csv -Path $File -Delimiter ","

	ForEach ($Acct in $Accts) {
		$storeNumber = $Acct.dtlr_key
		$storeFirstName = $Acct.dtlr_key
		$storeLastName = $Acct.store_long
		$storeDisplayName = $storeFirstName + " " + $storeLastName
		$OU = "OU=Villa,OU=Stores,OU=Users,OU=Corporate Office,OU=DTLR,DC=levtrannt,DC=lan"
		$UPN = $Acct.dtlr_key + "@dtlr.com"

		New-ADUser -Name "$storeDisplayName" -DisplayName "$storeDisplayName" -SamAccountName $Acct.dtlr_key
		 -GivenName $Acct.dtlr_key -Surname $Acct.store_long -UserPrincipalName $UPN -Path "$OU"
		 -PasswordNeverExpires $true -ChangePasswordAtLogon $false -CannotChangePassword $true -Department "Operations"
		 -StreetAddress $Acct.store_address -PostalCode $Acct.store_zip -State $Acct.store_state -City $Acct.store_city
	}
}
