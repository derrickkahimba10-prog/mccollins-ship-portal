<div class="form-grid">
<div class="field full"><label>Carrier type</label><select name="owner_type" id="owner_type" required><option value="individual" <?=($values['owner_type']??'')==='individual'?'selected':''?>>Individual truck owner</option><option value="company" <?=($values['owner_type']??'')==='company'?'selected':''?>>Carrier company</option></select></div>
<div class="field company-field"><label>Company legal name</label><input name="legal_name" maxlength="191" value="<?=h($values['legal_name']??'')?>"></div>
<div class="field company-field"><label>Company display name</label><input name="display_name" maxlength="191" value="<?=h($values['display_name']??'')?>"></div>
<div class="field company-field"><label>Registration number</label><input name="registration_number" maxlength="96" value="<?=h($values['registration_number']??'')?>"></div>
<div class="field"><label>Registration country</label><input name="registration_country" maxlength="2" required value="<?=h($values['registration_country']??'TZ')?>"></div>
<div class="field"><label>TIN</label><input name="tin_number" maxlength="96" required value="<?=h($values['tin_number']??'')?>"></div>
<div class="field"><label>Business licence number</label><input name="business_license_number" maxlength="96" required value="<?=h($values['business_license_number']??'')?>"></div>
<div class="field"><label>Business licence expiry <span class="muted">(if applicable)</span></label><input type="date" name="business_license_expiry" value="<?=h($values['business_license_expiry']??'')?>"></div>
<div class="field"><label>Insurance provider</label><input name="insurance_provider" maxlength="191" required value="<?=h($values['insurance_provider']??'')?>"></div>
<div class="field"><label>Insurance policy number</label><input name="insurance_policy_number" maxlength="96" required value="<?=h($values['insurance_policy_number']??'')?>"></div>
<div class="field"><label>Insurance expiry <span class="muted">(if applicable)</span></label><input type="date" name="insurance_expiry" value="<?=h($values['insurance_expiry']??'')?>"></div>
<h3 class="field full">Registered address</h3>
<div class="field full"><label>Address line 1</label><input name="line_1" maxlength="191" required value="<?=h($values['line_1']??'')?>"></div>
<div class="field"><label>Address line 2</label><input name="line_2" maxlength="191" value="<?=h($values['line_2']??'')?>"></div>
<div class="field"><label>City</label><input name="city" maxlength="120" value="<?=h($values['city']??'')?>"></div>
<div class="field"><label>Region</label><input name="region" maxlength="120" value="<?=h($values['region']??'')?>"></div>
<div class="field"><label>Postal code</label><input name="postal_code" maxlength="32" value="<?=h($values['postal_code']??'')?>"></div>
</div><script>(function(){const s=document.getElementById('owner_type');function show(){document.querySelectorAll('.company-field').forEach(e=>e.style.display=s.value==='company'?'grid':'none')}s.addEventListener('change',show);show()})();</script>
