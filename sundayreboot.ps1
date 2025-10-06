$list1= @(1,2,3,4)
$list2= @(5,6,7,8)

for($i -eq 0;$i -le $list1.Length ; $i++){
    Write-Output($i)
}