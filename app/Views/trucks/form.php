<div class="form-grid">
<h3 class="field full">Truck identity</h3>
<div class="field"><label>Registration number</label><input name="registration_number" maxlength="64" required value="<?=h($values['registration_number']??'')?>"></div>
<div class="field"><label>Registration country</label><input name="registration_country" maxlength="2" required value="<?=h($values['registration_country']??'TZ')?>"></div>
<div class="field"><label>Make</label><input name="make_name" maxlength="96" required value="<?=h($values['make_name']??'')?>"></div>
<div class="field"><label>Model</label><input name="model_name" maxlength="96" required value="<?=h($values['model_name']??'')?>"></div>
<div class="field"><label>Manufacture year</label><input type="number" name="manufacture_year" min="1900" max="<?=h((int)date('Y')+1)?>" required value="<?=h($values['manufacture_year']??'')?>"></div>
<div class="field"><label>Chassis number</label><input name="chassis_number" maxlength="96" required value="<?=h($values['chassis_number']??'')?>"></div>
<div class="field"><label>Engine number <span class="muted">(optional)</span></label><input name="engine_number" maxlength="96" value="<?=h($values['engine_number']??'')?>"></div>
<div class="field"><label>Body type</label><select name="body_type_code" required><option value="">Choose</option><?php foreach(\App\Services\TruckService::bodyTypes() as$o):?><option value="<?=h($o)?>" <?=($values['body_type_code']??'')===$o?'selected':''?>><?=h(str_replace('_',' ',$o))?></option><?php endforeach;?></select></div>
<div class="field"><label>Capacity</label><input type="number" step="0.001" min="0.001" name="capacity_value" required value="<?=h($values['capacity_value']??'')?>"></div>
<div class="field"><label>Capacity unit</label><select name="capacity_unit" required><option value="">Choose</option><?php foreach(\App\Services\TruckService::capacityUnits() as$o):?><option value="<?=h($o)?>" <?=($values['capacity_unit']??'')===$o?'selected':''?>><?=h($o)?></option><?php endforeach;?></select></div>
<h3 class="field full">Insurance reference</h3>
<div class="field"><label>Provider</label><input name="provider_name" maxlength="191" required value="<?=h($values['provider_name']??'')?>"></div>
<div class="field"><label>Policy number</label><input name="policy_number" maxlength="96" required value="<?=h($values['policy_number']??'')?>"></div>
<div class="field"><label>Coverage type</label><input name="coverage_type" maxlength="96" required value="<?=h($values['coverage_type']??'')?>"></div>
<div class="field"><label>Valid from</label><input type="date" name="insurance_valid_from" required value="<?=h($values['insurance_valid_from']??'')?>"></div>
<div class="field"><label>Valid to</label><input type="date" name="insurance_valid_to" required value="<?=h($values['insurance_valid_to']??'')?>"></div>
<h3 class="field full">Inspection and roadworthiness</h3>
<div class="field"><label>Inspection certificate/reference</label><input name="inspection_number" maxlength="96" required value="<?=h($values['inspection_number']??'')?>"></div>
<div class="field"><label>Inspected on</label><input type="date" name="inspected_on" required value="<?=h($values['inspected_on']??'')?>"></div>
<div class="field"><label>Inspection expires</label><input type="date" name="inspection_expires_on" required value="<?=h($values['inspection_expires_on']??'')?>"></div>
<div class="field"><label>Inspection result</label><select name="result_code" required><option value="PASS" <?=($values['result_code']??'')==='PASS'?'selected':''?>>PASS</option><option value="FAIL" <?=($values['result_code']??'')==='FAIL'?'selected':''?>>FAIL</option></select></div>
<div class="field"><label>Roadworthiness</label><select name="roadworthiness_status" required><option value="ROADWORTHY" <?=($values['roadworthiness_status']??'')==='ROADWORTHY'?'selected':''?>>ROADWORTHY</option><option value="NOT_ROADWORTHY" <?=($values['roadworthiness_status']??'')==='NOT_ROADWORTHY'?'selected':''?>>NOT ROADWORTHY</option></select></div>
</div>
