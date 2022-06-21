AEM Profiles and required artifacts
-----------------------------------

The table further below lists down the artifacts required for a given AEM profile.

The file names _must_ be identical to what's listed here. These names are exactly the asset file names on [Adobe Package Share](https://www.adobeaemcloud.com/content/packageshare.html) .

There is no obvious file name convention because Adobe has historically been publishing the artifacts with inconsistent naming between versions.

For AEM 6.5, the service pack file names used to have the format `AEM-6.5.x.0-6.5.x.zip` when the artifacts were distributed via adobeaemcloud.com . However, the naming convention has been changed to `aem-service-pkg-6.5.x.zip` when the artifacts distribution was moved to 

| AEM Profile | Required Artifacts |
|-------------|--------------------|
| `aem62` | license-6.2.properties, AEM_6.2_Quickstart.jar, cq-6.2.0-hotfix-11490-1.2.zip, cq-6.2.0-hotfix-12785-7.0.zip, cq-6.2.0-hotfix-15607-1.0.zip |
| `aem62_sp1` | `aem62` artifacts + AEM-6.2-Service-Pack-1-6.2.SP1.zip |
| `aem62_sp1_cfp9` | `aem62_sp1` artifacts + AEM-6.2-SP1-CFP9-9.0.zip |
| `aem62_sp1_cfp13` | `aem62_sp1` artifacts + AEM-6.2-SP1-CFP13-13.0.zip |
| `aem62_sp1_cfp15` | `aem62_sp1` artifacts + AEM-6.2-SP1-CFP15-15.0.zip |
| `aem62_sp1_cfp18` | `aem62_sp1` artifacts + AEM-6.2-SP1-CFP18-18.0.zip |
| `aem62_sp1_cfp20` | `aem62_sp1` artifacts + AEM-6.2-SP1-CFP20-20.0.zip |
| `aem63` | license-6.3.properties, AEM_6.3_Quickstart.jar |
| `aem63_sp1` | `aem63` artifacts + AEM-6.3-Service-Pack-1-6.3.SP1.zip |
| `aem63_sp1_cfp2` | `aem63_sp1` artifacts + AEM-CFP-6.3.1.2-2.0.zip |
| `aem63_sp2` | `aem63` artifacts + AEM-6.3.2.0-6.3.2.zip |
| `aem63_sp2_cfp1` | `aem63_sp2` artifacts + AEM-CFP-6.3.2.1-1.0.zip |
| `aem63_sp2_cfp2` | `aem63_sp2` artifacts + AEM-CFP-6.3.2.2-2.0.zip |
| `aem64` | license-6.4.properties, AEM_6.4_Quickstart.jar |
| `aem64_sp1` | `aem64` artifacts + AEM-6.4.1.0-6.4.1.zip |
| `aem64_sp2` | `aem64` artifacts + AEM-6.4.2.0-6.4.2.zip |
| `aem64_sp3` | `aem64` artifacts + AEM-6.4.3.0-6.4.3.zip |
| `aem64_sp4` | `aem64` artifacts + AEM-6.4.4.0-6.4.4.zip |
| `aem65` | license-6.5.properties, AEM_6.5_Quickstart.jar |
| `aem65_sp1` | `aem65` artifacts + AEM-6.5.1.0-6.5.1.zip |
| `aem65_sp2` | `aem65` artifacts + AEM-6.5.2.0-6.5.2.zip |
| `aem65_sp3` | `aem65` artifacts + AEM-6.5.3.0-6.5.3.zip |
| `aem65_sp7` | `aem65` artifacts + aem-service-pkg-6.5.7.zip |
| `aem65_sp8` | `aem65` artifacts + aem-service-pkg-6.5.8.zip |
| `aem65_sp9` | `aem65` artifacts + aem-service-pkg-6.5.9.zip |
| `aem65_sp10` | `aem65` artifacts + aem-service-pkg-6.5.10.zip |
| `aem65_sp11` | `aem65` artifacts + aem-service-pkg-6.5.11.zip |
| `aem65_sp13` | `aem65` artifacts + aem-service-pkg-6.5.13.zip |
