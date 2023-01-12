<#
.SYNOPSIS
	Enumerate error record details.
.DESCRIPTION
	Enumerate an error record, or a collection of error record, properties. By default, the details for the last error will be enumerated.
.PARAMETER ErrorRecord
	The error record to resolve. The default error record is the latest one: $global:Error[0]. This parameter will also accept an array of error records.
.PARAMETER Property
	The list of properties to display from the error record. Use "*" to display all properties.
	Default list of error properties is: Message, FullyQualifiedErrorId, ScriptStackTrace, PositionMessage, InnerException
.PARAMETER GetErrorRecord
	Get error record details as represented by $_.
.PARAMETER GetErrorInvocation
	Get error record invocation information as represented by $_.InvocationInfo.
.PARAMETER GetErrorException
	Get error record exception details as represented by $_.Exception.
.PARAMETER GetErrorInnerException
	Get error record inner exception details as represented by $_.Exception.InnerException. Will retrieve all inner exceptions if there is more than one.
.EXAMPLE
	Resolve-Error
.EXAMPLE
	Resolve-Error -Property *
.EXAMPLE
	Resolve-Error -Property InnerException
.EXAMPLE
	Resolve-Error -GetErrorInvocation:$false
.NOTES
.LINK
	http://psappdeploytoolkit.com
#>
function Resolve-Error {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $false,
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
            )]
		[AllowEmptyCollection()]
		[array]
        $ErrorRecord,

		[Parameter(Mandatory = $false, Position = 1)]
		[ValidateNotNullorEmpty()]
		[string[]]
        $Property = ('Message', 'InnerException', 'FullyQualifiedErrorId', 'ScriptStackTrace', 'PositionMessage'),

		[Parameter(Mandatory = $false, Position = 2)]
		[switch]
        $SkipGetErrorRecord,

		[Parameter(Mandatory = $false, Position = 3)]
		[switch]
        $SkipGetErrorInvocation,

		[Parameter(Mandatory = $false, Position = 4)]
		[switch]
        $SkipGetErrorException,

		[Parameter(Mandatory = $false, Position = 5)]
		[switch]
        $SkipGetErrorInnerException
	)

	begin {
		## If function was called without specifying an error record, then choose the latest error that occurred
		if (-not $ErrorRecord) {
			if ($global:Error.Count -eq 0) {
				# Microsoft.PowerShell.Utility\Write-Information -Message 'The $Error collection is empty' -Tags 'VertigoRay\PSWriteLog','Resolve-Error'
				return
			}
			Else {
				[array] $ErrorRecord = $global:Error[0]
			}
		}

		## Allows selecting and filtering the properties on the error object if they exist
		[scriptblock] $selectProperty = {
			param(
				[Parameter(Mandatory = $true)]
				[ValidateNotNullorEmpty()]
				$InputObject,

				[Parameter(Mandatory = $true)]
				[ValidateNotNullorEmpty()]
				[string[]]
                $Property
			)

			[string[]] $objectProperty = $InputObject | Get-Member -MemberType '*Property' | Select-Object -ExpandProperty 'Name'
			foreach ($prop in $Property) {
				if ($prop -eq '*') {
					[string[]] $propertySelection = $objectProperty
					Break
				}
				Elseif ($objectProperty -contains $prop) {
					[string[]] $propertySelection += $prop
				}
			}
			return $propertySelection
		}

		#  Initialize variables to avoid error if 'Set-StrictMode' is set
		$logErrorRecordMsg = $null
		$logErrorInvocationMsg = $null
		$logErrorExceptionMsg = $null
		$logErrorMessageTmp = $null
		$logInnerMessage = $null
	}
	process {
		if (-not $ErrorRecord) { return }
		foreach ($errRecord in $ErrorRecord) {
			## Capture Error Record
			if (-not $SkipErrorRecord) {
				[string[]] $selectedProperties = & $selectProperty -InputObject $errRecord -Property $Property
				$logErrorRecordMsg = $errRecord | Select-Object -Property $selectedProperties
			}

			## Error Invocation Information
			if (-not $SkipGetErrorInvocation) {
				if ($errRecord.InvocationInfo) {
					[string[]] $selectedProperties = & $selectProperty -InputObject $errRecord.InvocationInfo -Property $Property
					$logErrorInvocationMsg = $errRecord.InvocationInfo | Select-Object -Property $selectedProperties
				}
			}

			## Capture Error Exception
			if (-not $SkipGetErrorException) {
				if ($errRecord.Exception) {
					[string[]] $selectedProperties = & $selectProperty -InputObject $errRecord.Exception -Property $Property
					$logErrorExceptionMsg = $errRecord.Exception | Select-Object -Property $selectedProperties
				}
			}

			## Display properties in the correct order
			if ($Property -eq '*') {
				#  If all properties were chosen for display, then arrange them in the order the error object displays them by default.
				if ($logErrorRecordMsg) { [array] $logErrorMessageTmp += $logErrorRecordMsg }
				if ($logErrorInvocationMsg) { [array] $logErrorMessageTmp += $logErrorInvocationMsg }
				if ($logErrorExceptionMsg) { [array] $logErrorMessageTmp += $logErrorExceptionMsg }
			}
			Else {
				#  Display selected properties in our custom order
				if ($logErrorExceptionMsg) { [array] $logErrorMessageTmp += $logErrorExceptionMsg }
				if ($logErrorRecordMsg) { [array] $logErrorMessageTmp += $logErrorRecordMsg }
				if ($logErrorInvocationMsg) { [array] $logErrorMessageTmp += $logErrorInvocationMsg }
			}

			if ($logErrorMessageTmp) {
				$logErrorMessage = 'Error Record:'
				$logErrorMessage += "`n-------------"
				$logErrorMsg = $logErrorMessageTmp | Format-List | Out-String
				$logErrorMessage += $logErrorMsg
			}

			## Capture Error Inner Exception(s)
			if (-not $SkipGetErrorInnerException) {
				if ($errRecord.Exception -and $errRecord.Exception.InnerException) {
					$logInnerMessage = 'Error Inner Exception(s):'
					$logInnerMessage += "`n-------------------------"

					$errorInnerException = $errRecord.Exception.InnerException
					$count = 0

					while ($errorInnerException) {
						[string] $InnerExceptionSeperator = '~' * 40

						[string[]] $selectedProperties = & $selectProperty -InputObject $errorInnerException -Property $Property
						$logerrorInnerExceptionMsg = $errorInnerException | Select-Object -Property $selectedProperties | Format-List | Out-String

						if ($count -gt 0) { $logInnerMessage += $InnerExceptionSeperator }
						$logInnerMessage += $logerrorInnerExceptionMsg

						$count++
						$errorInnerException = $errorInnerException.InnerException
					}
				}
			}

			if ($logErrorMessage) { $output = $logErrorMessage }
			if ($logInnerMessage) { $output += $logInnerMessage }

			Write-Output -InputObject $output

			if (Test-Path -LiteralPath 'variable:Output') { Clear-Variable -Name 'Output' }
			if (Test-Path -LiteralPath 'variable:LogErrorMessage') { Clear-Variable -Name 'LogErrorMessage' }
			if (Test-Path -LiteralPath 'variable:LogInnerMessage') { Clear-Variable -Name 'LogInnerMessage' }
			if (Test-Path -LiteralPath 'variable:LogErrorMessageTmp') { Clear-Variable -Name 'LogErrorMessageTmp' }
		}
	}
	end {
	}
}