function Get-DbaServerAudit {
    <#
    .SYNOPSIS
        Gets SQL Security Audit information for each instance(s) of SQL Server.

    .DESCRIPTION
        The Get-DbaServerAudit command gets SQL Security Audit information for each instance(s) of SQL Server.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. This can be a collection and receive pipeline input to allow the function
        to be executed against multiple SQL Server instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER Audit
        Return only specific audits

    .PARAMETER ExcludeAudit
        Exclude specific audits

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: Audit, Security, SqlAudit
        Author: Garry Bargsley (@gbargsley), http://blog.garrybargsley.com

        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Get-DbaServerAudit

    .EXAMPLE
        PS C:\> Get-DbaServerAudit -SqlInstance localhost

        Returns all Security Audits on the local default SQL Server instance

    .EXAMPLE
        PS C:\> Get-DbaServerAudit -SqlInstance localhost, sql2016

        Returns all Security Audits for the local and sql2016 SQL Server instances

    #>
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [Alias("Credential")]
        [PSCredential]$SqlCredential,
        [string[]]$Audit,
        [string[]]$ExcludeAudit,
        [Alias('Silent')]
        [switch]$EnableException
    )

    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $SqlCredential -MinimumVersion 10
            } catch {
                Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            $audits = $server.Audits

            if (Test-Bound -ParameterName Audit) {
                $audits = $audits | Where-Object Name -in $Audit
            }
            if (Test-Bound -ParameterName ExcludeAudit) {
                $audits = $audits | Where-Object Name -notin $ExcludeAudit
            }

            foreach ($currentaudit in $audits) {
                $directory = $currentaudit.FilePath.TrimEnd("\")
                $filename = $currentaudit.FileName
                $fullname = "$directory\$filename"
                $remote = $fullname.Replace(":", "$")
                $remote = "\\$($currentaudit.Parent.ComputerName)\$remote"

                Add-Member -Force -InputObject $currentaudit -MemberType NoteProperty -Name ComputerName -value $currentaudit.Parent.ComputerName
                Add-Member -Force -InputObject $currentaudit -MemberType NoteProperty -Name InstanceName -value $currentaudit.Parent.ServiceName
                Add-Member -Force -InputObject $currentaudit -MemberType NoteProperty -Name SqlInstance -value $currentaudit.Parent.DomainInstanceName
                Add-Member -Force -InputObject $currentaudit -MemberType NoteProperty -Name FullName -value $fullname
                Add-Member -Force -InputObject $currentaudit -MemberType NoteProperty -Name RemoteFullName -value $remote

                Select-DefaultView -InputObject $currentaudit -Property ComputerName, InstanceName, SqlInstance, Name, 'Enabled as IsEnabled', FullName
            }
        }
    }
}