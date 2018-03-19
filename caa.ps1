Function Get-RandomPassword {
	Param (
		[int]$Length = 10
	)

	$wordList = Get-Content -Path ".\wordlist.txt"
	$randomWordArrayget = [array](Get-Random -Maximum ([array]$wordList.count))
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

Function Add-DTLRAccountsExchange {
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[ValidatePattern('\.csv$')]
		[string]$File
	)

	$Accts = Import-Csv -Path $File -Delimiter ","
	$SourceGroups = Get-ADUser "015" -Property MemberOf | ForEach-Object {
		$_.MemberOf | Get-ADGroup | Select-Object Name -ExpandProperty Name | sort name
	}

	ForEach ($Acct in $Accts) {
		$storeNumber = $Acct.dtlr_key
		$storeFirstName = $Acct.dtlr_key
		$storeLastName = $Acct.store_long
		$storeDisplayName = $storeFirstName + " " + $storeLastName
		$OU = "OU=Villa,OU=Stores,OU=Users,OU=Corporate Office,OU=DTLR,DC=levtrannt,DC=lan"
		$UPN = $Acct.dtlr_key + "@dtlr.com"

		$password = ""

		New-Mailbox
			-UserPrincipalName $UPN
			-Password
			-Database "DB_Stores"
			-Name "$storeDisplayName"
			-DisplayName "$storeDisplayName"
			-SamAccountName $Acct.dtlr_key
			-FirstName $Acct.dtlr_key
			-LastName $Acct.store_long
			-OrganizationalUnit "$OU"
			-RetentionPolicy "DTLR_14_Day"
		 	-ResetPasswordOnNextLogon $false

		Get-ADUser -Filter "UserPrincipalName -eq '$UPN'" |
			Set-ADUser -Replace @{
				Department = "Operations";
				PasswordNeverExpires = $true;
				CannotChangePassword = $true;
				StreeAddress = $Acct.store_address;
				PostalCode = $Acct.store_zip;
				State = $Acct.store_state;
				City = $Acct.store_city;
			}

		ForEach ($Group in $SourceGroups) {
			Add-ADGroupMember $Group -Member $storeNumber
		}
	}
}
