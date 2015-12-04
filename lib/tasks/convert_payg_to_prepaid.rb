## Meant to be run only once to convert all existing PAYG servers to Prepaid payment method

task convert_payg_to_prepaid: :environment do
  ConvertPaygToPrepaid.run
end
