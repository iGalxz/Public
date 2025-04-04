$Printer = New-Object -TypeName PSObject -Property @{
                PrinterName = "$DynamicPrinterNameChosenInTheAdvancedInsightsConsole"
                PrinterIP   = "xxx.xxx.xxx.xxx"
                PrinterPortName = "IP_xxx.xxx.xxx.xxx"
                DriverName = "Name of Print Driver Registered in Driver Store"
            }
           Add-PrinterPort -Name $Printer.PrinterPortName -PrinterHostAddress $Printer.PrinterIP
          Add-Printer -Name $Printer.PrinterName -DriverName $Printer.DriverName -PortName $Printer.PrinterPortName
