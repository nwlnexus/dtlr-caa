<#
.SYNOPSIS
    Creates random password string of length 1 to 100.
.DESCRIPTION
    Creates random password with ability to choose what characters are in the string and the length, the symbols can be specificlly defined.
.EXAMPLE
    New-RandomPassword -Length 8 -Lowercase
    In this example, a random string that consists of 8 lowercase charcters will be returned.
.EXAMPLE
    New-RandomPassword -Length 15 -Lowercase -Uppercase -Numbers -Symbols
    In this example, a random string that consists of 15 lowercase, uppercase, alpha-numeric and symbols will be returned.
.LINK
    http://www.asciitable.com/
    https://gist.github.com/PowerShellSith
#>
function New-RandomPassword {
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Length, Type uint32, Length of the random string to create.
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidatePattern('[0-9]+')]
        [ValidateRange(1, 100)]
        [uint32]
        $Length,

        # Lowercase, Type switch, Use lowercase characters.
        [Parameter(Mandatory = $false)]
        [switch]
        $Lowercase = $false,

        # Uppercase, Type switch, Use uppercase characters.
        [Parameter(Mandatory = $false)]
        [switch]
        $Uppercase = $false,

        # Numbers, Type switch, Use alphanumeric characters.
        [Parameter(Mandatory = $false)]
        [switch]
        $Numbers = $false,

        # Symbols, Type switch, Use symbol characters.
        [Parameter(Mandatory = $false)]
        [switch]$Symbols = $false
    )
    Begin {
        if (-not($Lowercase -or $Uppercase -or $Numbers -or $Symbols)) {
            throw "You must specify one of: -Lowercase -Uppercase -Numbers -Symbols"
        }

        # Specifies bitmap values for character sets selected.
        $CHARSET_LOWER = 1
        $CHARSET_UPPER = 2
        $CHARSET_NUMBER = 4
        $CHARSET_SYMBOL = 8

        # Creates character arrays for the different character classes, based on ASCII character values.
        $charsLower = 97..122 | % { [Char] $_ }
        $charsUpper = 65..90 | % { [Char] $_ }
        $charsNumber = 48..57 | % { [Char] $_ }
        $charsSymbol = 35, 36, 40, 41, 42, 44, 45, 46, 47, 58, 59, 63, 64, 92, 95 | % { [Char] $_ }
    }
    Process {
        # Contains the array of characters to use.
        $charList = @()
        # Contains bitmap of the character sets selected.
        $charSets = 0
        if ($Lowercase) {
            $charList += $charsLower
            $charSets = $charSets -bor $CHARSET_LOWER
        }
        if ($Uppercase) {
            $charList += $charsUpper
            $charSets = $charSets -bor $CHARSET_UPPER
        }
        if ($Numbers) {
            $charList += $charsNumber
            $charSets = $charSets -bor $CHARSET_NUMBER
        }
        if ($Symbols) {
            $charList += $charsSymbol
            $charSets = $charSets -bor $CHARSET_SYMBOL
        }

        <#
        .SYNOPSIS
            Test string for existnce specified character.
        .DESCRIPTION
            examins each character of a string to determine if it contains a specificed characters
        .EXAMPLE
            Test-StringContents i string
        #>
        function Test-StringContents([String] $test, [Char[]] $chars) {
            foreach ($char in $test.ToCharArray()) {
                if ($chars -ccontains $char) {
                    return $true
                }
            }
            return $false
        }

        do {
            # No character classes matched yet.
            $flags = 0
            $output = ""
            # Create output string containing random characters.
            1..$Length | % { $output += $charList[(get-random -maximum $charList.Length)] }

            # Check if character classes match.
            if ($Lowercase) {
                if (Test-StringContents $output $charsLower) {
                    $flags = $flags -bor $CHARSET_LOWER
                }
            }
            if ($Uppercase) {
                if (Test-StringContents $output $charsUpper) {
                    $flags = $flags -bor $CHARSET_UPPER
                }
            }
            if ($Numbers) {
                if (Test-StringContents $output $charsNumber) {
                    $flags = $flags -bor $CHARSET_NUMBER
                }
            }
            if ($Symbols) {
                if (Test-StringContents $output $charsSymbol) {
                    $flags = $flags -bor $CHARSET_SYMBOL
                }
            }
        }
        until ($flags -eq $charSets)
    }
    End {
        $output
    }
}

Function Get-RandomPassword {

    $wordList = Get-Content -Path ".\wordlist.txt"
    $rdm = $wordList | Get-Random -Maximum $wordList.count | Select-Object -First 1
    $tmpPassword = (Get-Culture).TextInfo.ToTitleCase($wordList[$rdm])

    $asciiNumbers = $null
    $asciiSpecials = $null

    For ($a = 48; $a -le 57; $a++) { $asciiNumbers += , [char][byte]$a }
    33, 35, 36, 37, 38, 63, 94 | Foreach-Object { $asciiSpecials += , [char][byte]$_ }


    if ($tmpPassword.Length -ge 10) {
		$n = $asciiSpecials | Get-Random
		$s = $asciiNumbers | Get-Random
        $tmpPassword = -join ($tmpPassword, $n, $s)
    }
    else {
        $needed = 10 - $tmpPassword.Length
		$ascii = $asciiNumbers + $asciiSpecials
		$randomSegment = -join ($ascii | Get-Random -Count $needed)
        $tmpPassword = -join ($tmpPassword, $randomSegment )
    }

	return $tmpPassword
}

Function Add-DTLRAccounts {
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
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
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
        [ValidatePattern('\.csv$')]
        [string]$File
    )

    $Accts = Import-Csv -Path $File -Delimiter ","
    $SourceGroups = Get-ADUser "015" -Property MemberOf | ForEach-Object {
        $_.MemberOf | Get-ADGroup | Select-Object Name -ExpandProperty Name | sort name
    }

    ForEach ($Acct in $Accts) {
		$storeNumber = ($Acct.dtlr_key).trim()
		$storeLongName = ($Acct.store_long).trim()
        $storeDisplayName = $storeNumber + " " + $storeLongName
        $OU = "OU=Villa,OU=Stores,OU=Users,OU=Corporate Office,OU=DTLR,DC=levtrannt,DC=lan"
        $UPN = $storeNumber + "@dtlr.com"

        $password = Get-RandomPassword

        New-Mailbox `
        	-UserPrincipalName $UPN `
        	-Password (ConvertTo-SecureString $password -AsPlainText -Force) `
        	-Database "DB_Stores" `
        	-Name $storeDisplayName `
        	-DisplayName $storeDisplayName `
        	-SamAccountName $storeNumber `
        	-FirstName $storeNumber `
        	-LastName $storeLongName `
        	-OrganizationalUnit $OU
        	-RetentionPolicy "DTLR_14_Day"
        	-ResetPasswordOnNextLogon $false

        Get-ADUser -Filter "UserPrincipalName -eq '$UPN'" |
            Set-ADUser -Replace @{
            Department           = "Operations";
            PasswordNeverExpires = $true;
            CannotChangePassword = $true;
            StreeAddress         = ($Acct.store_address).trim();
            PostalCode           = ($Acct.store_zip).trim();
            State                = ($Acct.store_state).trim();
            City                 = ($Acct.store_city).trim();
        }

        ForEach ($Group in $SourceGroups) {
            Add-ADGroupMember $Group -Member $Acct.dtlr_key
		}

		"$storeNumber, $UPN, $password" | Out-File -FilePath ".\output.txt" -Append
    }
}
