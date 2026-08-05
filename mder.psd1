#
# Module manifest for module 'DEPTH'
#
# Generated on: 1/24/2025
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'mder.psm1'

    # Version number of this module.
    ModuleVersion     = '2.1.0.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = '79290ab6-dff2-4be0-90b1-4cfa24f05693'

    # Author of this module
    Author            = 'DISA ID3'

    # Company or vendor of this module
    CompanyName       = 'Defense Information Systems Agency'

    # Copyright statement for this module
    Copyright         = 'Copyright (c) Microsoft Corporation.'

    # Description of the functionality provided by this module
    Description       = 'PowerShell Module to collect Master Device Endpoint Record (MDER) data on endpoints and write it into the Windows Registry. Originally created by Microsoft for DoD use.'

    # Minimum version of the PowerShell engine required by this module
    # PowerShellVersion = ''

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = 'Get-DepthData'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    # VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
# SIG # Begin signature block
# MIIkJwYJKoZIhvcNAQcCoIIkGDCCJBQCAQExDzANBglghkgBZQMEAgMFADCBmwYK
# KwYBBAGCNwIBBKCBjDCBiTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63
# JNLGKX7zUQIBAAIBAAIBAAIBAAIBADBRMA0GCWCGSAFlAwQCAwUABEBJQ8FQDxQE
# 7xG8O0Ui7gno0+0rJvRA71sPYy/Rxp1CapGm68D1e8y5FJBEuawSYv2o6FVEDPG2
# rnQV3xfg3+e0oIIJcDCCBI8wggN3oAMCAQICAgcNMA0GCSqGSIb3DQEBCwUAMFsx
# CzAJBgNVBAYTAlVTMRgwFgYDVQQKEw9VLlMuIEdvdmVybm1lbnQxDDAKBgNVBAsT
# A0RvRDEMMAoGA1UECxMDUEtJMRYwFAYDVQQDEw1Eb0QgUm9vdCBDQSAzMB4XDTIy
# MTIwNjE3MTM0OVoXDTI4MTIwNjE3MTM0OVowWjELMAkGA1UEBhMCVVMxGDAWBgNV
# BAoTD1UuUy4gR292ZXJubWVudDEMMAoGA1UECxMDRG9EMQwwCgYDVQQLEwNQS0kx
# FTATBgNVBAMTDERPRCBTVyBDQS03NTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAKZwD1SZnE8Nf3BkcBIb8+EK0936NHw7gLL9EN83mwwwJEfxOtoyYLSm
# fm5KyCUUbXHRgOayqP+lXgFI9/99M0UxNjQ9IrfFMuv5X1KVJm59BnwThMYjowGf
# NZx70sFsU6TpQuRGl453fgLYzg5RA8P1MB7J7EFDY/PzSSiRMTLoEHsi5+YzT2b5
# 6H9azywJN0o778E8V/pMVpskMqkAzcSFSmoy4AaREzXpsRaJwxY7cGY/DvDHsPVX
# UvtwkzWS87/SY7mKPAyPQ0mqcByC8lkBkFBO+gyqD8vAqPT0vXDentjOaVok5rcs
# dVx15qZkl+49ylHdwfcl5jJx3Xp3dGMCAwEAAaOCAVwwggFYMB8GA1UdIwQYMBaA
# FGyKlKJ3sYByHYF6Fqry3M5m7kXAMB0GA1UdDgQWBBToWK6zR627Ud4gDYfzFeTq
# PryLOjAOBgNVHQ8BAf8EBAMCAYYwPQYDVR0gBDYwNDALBglghkgBZQIBCyQwCwYJ
# YIZIAWUCAQsnMAsGCWCGSAFlAgELKjALBglghkgBZQIBCzswEgYDVR0TAQH/BAgw
# BgEB/wIBADAMBgNVHSQEBTADgAEAMDcGA1UdHwQwMC4wLKAqoCiGJmh0dHA6Ly9j
# cmwuZGlzYS5taWwvY3JsL0RPRFJPT1RDQTMuY3JsMGwGCCsGAQUFBwEBBGAwXjA6
# BggrBgEFBQcwAoYuaHR0cDovL2NybC5kaXNhLm1pbC9pc3N1ZWR0by9ET0RST09U
# Q0EzX0lULnA3YzAgBggrBgEFBQcwAYYUaHR0cDovL29jc3AuZGlzYS5taWwwDQYJ
# KoZIhvcNAQELBQADggEBADIIgI9eFJBbHLGTCRHhrCFubfDGzcvcW7L4wjKTqrAJ
# nBB6JaEbkTWqz3rKEIcpM9Jh8mk5jFF7Bo3zeKEP4By5/hdZN2fjh8aPg50j08zk
# 0lIISpyheVFKzw6uiXSHy41qz2y7j0ii8SZT6jBNavetvqpfn+TIOcPQngYtTkSc
# p5F/8s999rMnQoENxpC8/GEcr2R+Sa3YOrw0K+KhTLdpJgVCFqu1AyPxtX5lCO0O
# 0e6rH58h4ajnVDQTYorPMqKHu4UQZdE2iIjQpiLTBWk5ext/GSPIC9qawBjRyE6U
# 422lq5QtgmAoLQqFqBppTapWAf6j4Ar5OdLEr8RS+3UwggTZMIIDwaADAgECAgMA
# 464wDQYJKoZIhvcNAQELBQAwWjELMAkGA1UEBhMCVVMxGDAWBgNVBAoTD1UuUy4g
# R292ZXJubWVudDEMMAoGA1UECxMDRG9EMQwwCgYDVQQLEwNQS0kxFTATBgNVBAMT
# DERPRCBTVyBDQS03NTAeFw0yNTA1MjgxNjIyMDlaFw0yODEyMDYxNzEzNDlaMHAx
# CzAJBgNVBAYTAlVTMRgwFgYDVQQKEw9VLlMuIEdvdmVybm1lbnQxDDAKBgNVBAsT
# A0RvRDEMMAoGA1UECxMDUEtJMQ0wCwYDVQQLEwRESVNBMRwwGgYDVQQDExNDUy5E
# SVNBLklEMy4wOC0wMDQzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# 0jDgaqnUxB/76bGuNhIp2fVOxYo8F9JRp4LHCapop/30rSuG/DTGQ7tTjpkl2oFj
# 19G7WinF1ZJgQkTK1iEiZM0rJll0jI1B5kFjr1+xNC/Ga9uIlgZqEPAzYwrjJ5Z6
# ljN+VNvfOggc98kwh+uCQKVhvnvK3qdKpMLiqnlaWSkza/VDzUlzGvK+lTl0dgy6
# doZXL7Iq2mgYuL7mFugzKx7KEnB3xMSyCqAURD4WJRQpg0K3wJOYFe8LND5wfUVL
# c4eQygL+g3J9sVOG2LUzfvByS1oLK6aR3Z23oCs7oRBRqtWJRmJ8KL5AmoPkjT5S
# 0/8dyS/c69ImIPje2MomtwIDAQABo4IBkDCCAYwwHwYDVR0jBBgwFoAU6Fius0et
# u1HeIA2H8xXk6j68izowHQYDVR0OBBYEFEU6Q+EQ3Ut4BxBet1S28gugApcOMGUG
# CCsGAQUFBwEBBFkwVzAzBggrBgEFBQcwAoYnaHR0cDovL2NybC5kaXNhLm1pbC9z
# aWduL0RPRFNXQ0FfNzUuY2VyMCAGCCsGAQUFBzABhhRodHRwOi8vb2NzcC5kaXNh
# Lm1pbDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwbQYDVR0R
# BGYwZKRiMGAxCzAJBgNVBAYTAlVTMRgwFgYDVQQKEw9VLlMuIEdvdmVybm1lbnQx
# DDAKBgNVBAsTA0RvRDEMMAoGA1UECxMDUEtJMQ0wCwYDVQQLEwRESVNBMQwwCgYD
# VQQDEwNJRDMwFgYDVR0gBA8wDTALBglghkgBZQIBCyowNwYDVR0fBDAwLjAsoCqg
# KIYmaHR0cDovL2NybC5kaXNhLm1pbC9jcmwvRE9EU1dDQV83NS5jcmwwDQYJKoZI
# hvcNAQELBQADggEBAD6AmoySflD+VwnjWaKlFbXs5VBvG0p8uI0iN8uiQS7XiJL1
# gb93WTFdCkGoCvRAny9FmhEX5JVhcy0aK0K0TlwQrKdTOuoap6B0w+H2b12U6JDj
# z/VKUTlLO7GW8RaA0AhsC+99NQeA6zMNU1IRBcUFVGRVPSkn3KE1V+l83eQH1SAX
# FTVhvvUI6UsZPrPV19m4XG9P6BYUNmd4uXfK6KnC42eH+hUoGkV4En/PC+EfWxx3
# SdCaJJDzRbGfZhSHSGjZdAByRi5zdEZ/KPiaMjvxW2BG1AGq60E25CXC775LZUOp
# bXZgqPK/PbyT2p2Cqy88/M7G7q5NsVTb0vyBF0AxghnqMIIZ5gIBATBhMFoxCzAJ
# BgNVBAYTAlVTMRgwFgYDVQQKEw9VLlMuIEdvdmVybm1lbnQxDDAKBgNVBAsTA0Rv
# RDEMMAoGA1UECxMDUEtJMRUwEwYDVQQDEwxET0QgU1cgQ0EtNzUCAwDjrjANBglg
# hkgBZQMEAgMFAKCBnDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTBPBgkqhkiG
# 9w0BCQQxQgRAe1qoGzgk+8NObXGyNchdzgLzchG/j+1SR27FSC6lJJOCtX8KSNtT
# P6UL9/IIDt/l+RekEzpp7L8p02C8RNnVhzANBgkqhkiG9w0BAQEFAASCAQAm13Lc
# 6Q1OSjR1fpC3I3P2XeFt+DQnKojBYGx5HzmU1A5OFt1s1z3dFEz+HK4hqSzx389Q
# 5vVV74F1xL6da0IKMADxlyz0iHMs0keguD9GdFE+YzdK7kKxlTVu4iVEL4Nt+aX8
# pe1omTTv7XNPk+KBl8iP3LAJZNB8+s/fypZyX6VgSc5vV8DKi8ahcMhdFO/JpAq9
# RLECQohwoCrwGMxqQNTiy4L3aAeB/MrO9feQDOXcrxaAclJE0s4Je1HwD5zkWuam
# X0UrBBjCdygcTl4oITIqbiwlN9khEXBykQiFnOMtciL1aXto1bJPs2GjbT6N9mRy
# sOw4E8SR002MDjeRoYIXuzCCF7cGCisGAQQBgjcDAwExghenMIIXowYJKoZIhvcN
# AQcCoIIXlDCCF5ACAQMxDzANBglghkgBZQMEAgMFADCBmwYLKoZIhvcNAQkQAQSg
# gYsEgYgwgYUCAQEGCWCGSAGG/WwHATBRMA0GCWCGSAFlAwQCAwUABECZQdCf/Z7r
# +S/GQi/bjb2RMVN98bxirufavD78Mzx4gD1GCaXyD0BRdEKkeLmDtxXLM6Eo2a2e
# Fmlg8cWdxuUSAhEAuyOg7PzjExa05mVtoe1N2hgPMjAyNTA3MTYyMjExMDhaoIIT
# OjCCBu0wggTVoAMCAQICEAgZdf6JtPswSxOAd9LT/kIwDQYJKoZIhvcNAQENBQAw
# aTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQD
# EzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1
# NiAyMDI1IENBMTAeFw0yNTA2MDQwMDAwMDBaFw0zNjA5MDMyMzU5NTlaMGMxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGln
# aUNlcnQgU0hBNTEyIFJTQTQwOTYgVGltZXN0YW1wIFJlc3BvbmRlciAyMDI1IDEw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCzuWUqov0KKmEsbpBNwmdz
# finluq/JUsfuhvt7sBAZizHZY1xBFKSWMxvfSBwFlcEkCGpgH+8n2VOpH4DrPSSr
# /GOi5I9EVdwD9Qu3LF62N8891VbVIk3vDAr/96B6F5oWg6ofLaWBUqnnVvXx3hnd
# GSyKK5gohAwDWm+q1FGg67NUwiiLctrUkcX19N0eNZaH6sH+Pc9Vj/l+szK7/ZNE
# uuOkx2HT8kGfSf7ajuGQySnhAPZPAq93Y5ZWgRNQyBxq1aMsMCnwMgoe3AN7nWAd
# 1Or/15uHWScRWch0JoJpO4UKpbNVbhYKGd3WTuWIiac5b1MjAWzbFq/8rhD3qqf+
# xfg6OQ1ignizYqs/VlXb1rmhuvIRv+G1z/d2uLp8PGnIXjNgsTpSlWGIAMCafCyf
# kTDszsukiJmqcrffWqlamFnXwl9F9S1Ah8zDkBmMhGguh7yrm+YYCzVqkc6jTxc7
# N79/TvKo4xgYPIOwGIkeZL7xyE6nxhAsxTEfukWkyiJ8ZfBTEWSSGz50YxXkPgeQ
# W8iQWDJPLKe09WuMiua1K2X/TvAXjcKr0n4miA676IdSwtUpqfHTqtLxZw7Bwo5l
# ClA0WVR+UqCkFojw7X/r5ClYtTgcWBt2faJ7616zkZctmtG/hTWm1YnunBSbMkO7
# p8zaY+RBMWJ4OQi+o1azXwIDAQABo4IBlTCCAZEwDAYDVR0TAQH/BAIwADAdBgNV
# HQ4EFgQUkzk3wRL12XQBYnuLVB89jzxkrRwwHwYDVR0jBBgwFoAU729TSunkBnx6
# yuKQVvYv1Ensy04wDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMIGVBggrBgEFBQcBAQSBiDCBhTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au
# ZGlnaWNlcnQuY29tMF0GCCsGAQUFBzAChlFodHRwOi8vY2FjZXJ0cy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2
# MjAyNUNBMS5jcnQwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1
# NjIwMjVDQTEuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAN
# BgkqhkiG9w0BAQ0FAAOCAgEAipDzmVW4KAinhERqkUBWMqZ/FUj/vogS7Ocehqki
# 86r3sdsJIXVo8Ngt6GhFUJ1GrjtcRGxhRe8hNvCy8BLjR8e7VrmHFopbh5ss/Bd9
# gORcterQE5K/lfDJza43GM1aXCBBhBV44hYKrUwkRFvdWBADSGCqo3dxwUSuYKv7
# K9P3solCxQ6cNpuAlGgyChmGJOFP0fMoy/qY/+ojtGknvWXWwwnzY5bpj6tW4RbY
# 88exdyClld3/ZUHMeJSkSy3TdEEEjcHNRuxlD03kePj6JnAEO/MZkymjVfQGvewh
# 0vWTOLM56+LAxJ/7H/6/79q/N16EssCCvPyrsfB37uWLQyxJLMwlhKb2eZbzR5lk
# lUdxudcqmyEux3tVLJCDklzErXR87Pf4+2oZinScT2j1ap1EiHVda/tlyhg3OZ0z
# 45+vnR+FnCIvkvy7k/QZM5lzhCb2flzOGk3SZZOxdMQ6XPx7q9LD1A3RX2dFuR8h
# sqGwlpIyDSI5X4WhZDWMoJbjWeSbQ2g8Y48TehnBuzu5xTtVRPQnup+PwFgJG8Ev
# jrViwPgeeXqFj6YknAHKhsRBAM7ZG6L2W4YO86+EmZ8mVLOAKZFY7Le7vKywdunX
# p9AzNh0fyyjC/yPLk63CgTKamngOVAWgjSBtJtUyTQ1LFp6uFknD0OwpEWTe5IAO
# MFwwgga0MIIEnKADAgECAhANx6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUA
# MGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT
# EHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9v
# dCBHNDAeFw0yNTA1MDcwMDAwMDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXb
# o0ZodLRRF51NrY0NlLWZloMsVO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjf
# EvUi6wuim5bap+0lgloM2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRin
# vuNgxVBdJkf77S2uPoCj7GH8BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4
# OtiFcMSkqTtF2hfQz3zQSku2Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9
# tUKJm/s80FiocSk1VYLZlDwFt+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiG
# PMvSGmhgaTzVyhYn4p0+8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66b
# kDX1ZlAeSpQl92QOMeRxykvq6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYG
# qLt9MmeOreGPRdtBx3yGOP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucu
# oKs7Yk/ehb//Wx+5kMqIMRvUBDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLi
# Q6bGRinZbI4OLu9BMIFm1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWu
# g/G6X5uAiynM7Bu2ayBjUwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIB
# ADAdBgNVHQ4EFgQU729TSunkBnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7Nfj
# gtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsG
# AQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au
# ZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0
# hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0
# LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcN
# AQELBQADggIBABfO+xaAHP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8Oju
# hUxjaaFdleMM0lBryPTQM2qEJPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJ
# gnn0hvrV6hqWGd3rLAUt6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee
# 5kH0F8HABBgr0UdqirZ7bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXq
# vcnTmpfeQh35k5zOCPmSNq1UH410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uH
# QcKfZxAvBAKqMVuqte69M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3
# anzEwlvzZiiyfTPjLbnFRsjsYg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoB
# dqbhOhZ3ZRDUphPvSRmMThi0vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQ
# DpOXgpIUsWTjd6xpR6oaQf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiK
# i9EOLLHfMR2ZyJ/+xhCx9yHbxtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qb
# p7wGWqbIiOWCnb5WqxL3/BAPvIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIFjTCC
# BHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0Ew
# HhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZ
# wuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4V
# pX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAd
# YyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3
# T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjU
# N6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNda
# SaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtm
# mnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyV
# w4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3
# AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYi
# Cd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmp
# sh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7Nfj
# gtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNt
# yA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUG
# A1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3
# DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+Ica
# aVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096ww
# epqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcD
# x4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsg
# jTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37Y
# OtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMYIDnDCCA5gCAQEwfTBpMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lD
# ZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUg
# Q0ExAhAIGXX+ibT7MEsTgHfS0/5CMA0GCWCGSAFlAwQCAwUAoIHxMBoGCSqGSIb3
# DQEJAzENBgsqhkiG9w0BCRABBDAcBgkqhkiG9w0BCQUxDxcNMjUwNzE2MjIxMTA4
# WjArBgsqhkiG9w0BCRACDDEcMBowGDAWBBR0N8I+glF8bb712tMVtLQLqqFlSzA3
# BgsqhkiG9w0BCRACLzEoMCYwJDAiBCD8DMAqPpAX3V+62wD/ABKm62KOncXutpxB
# pbzgq8qImTBPBgkqhkiG9w0BCQQxQgRAaM+FFKeZ5igDLF8OxtkgajJU5UmRnAe1
# ZJ9he6ED7ZfS1i0IgDucCuOL8fA8Ry/jfHBUpjY6dcg9jHaxKLaCvTANBgkqhkiG
# 9w0BAQEFAASCAgCwuIdvBs5Sp/iWvRrNxDPO/+6SclVXmZgXOEmPjoCuX46uqeK1
# wwVXfcMaqZKhdDWUom1jg/SSLrZsC2MUVkboxMywvpdF6JlAAVvlbq3/z2yQKHQX
# QGukSVJFu8o9tlwr0T2GpQ+6//3I/bFi4lX5ZTqB07aUhF5D/grhBm5hLTO6he9E
# ps9IIU8+fdkgUuIE0Ic2+FLh5aTRMMCoSVyLhzMCVMgA3N3mAHWViCWdiYmEC4x8
# 3XjLBmx4U6DyUxeiVV2O0ccUYD8z6JqKcaI8rIcNf72eRomOHoISR70ry5WVHkkc
# HXtkxl0mA5OqvLdOK2DxrG8YpNkj+529zzkpK0M7COVDdSUcQGFC0V+QmlysdruV
# K7rZSsKBmOssz6XDtcSS8VgyRnZeAB9muUgUoOpl5Deiwwgo6oKHin2AhMJReyw/
# ngAl/aHcGmJqrt3ZfdKyHPCv0kwvW+WQK6DzhkAGEksFLjW4rN3qlOCS83hlB6Qe
# 9j73yICg928ce7W1GhBO63fbeVt14Pt948apPVcPAQJ6qrTLH1LV6fsL+jleYTwV
# uUIzTshgD8VmS/e1gDhlW/l1vO6VgRZMOu7IB6W32t+tR9pDNabg3jIH1NLddvWn
# OuCgy/EmVu2Bn+qTkmFr4g/GZVIcbrZnzlzjOhiSSPIvCDBno1l98n1UOw==
# SIG # End signature block
