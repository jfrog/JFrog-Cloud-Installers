#!/usr/bin/env python
import io
import cfnlint
import sys
from pathlib import Path

custom_attributes = {
    'deterministic_ec2_instances':[
        'aws_ec2_instance',
        'aws_ec2_host',
        'aws_ec2fleet',
        'aws_autoscaling_autoscalinggroup'
    ]
}

def get_cfn(filename):
    _decoded, _issues = cfnlint.decode.decode(filename)
    if not _decoded:
        raise Exception("cfn-lint failed to load {} without errors. Failure".format(filename))
    return _decoded

def fetch_metadata():
    metadata_attributes = set()
    for yaml_cfn_file in Path('./templates').glob('*.template*'):
        template = get_cfn(Path(yaml_cfn_file))
        _resources = template['Resources']
        for _resource in _resources.values():
            _type = _resource['Type'].lower()
            metadata_attributes.add(_type.split('::')[1])
            metadata_attributes.add(_type.replace('::','_'))
        for attribute, qualifying_conditions in custom_attributes.items():
            for qc in qualifying_conditions:
                if qc in metadata_attributes:
                    metadata_attributes.add(attribute)
                    break
    with open('docs/generated/services/metadata.adoc', 'w') as f:
        f.write('\n')
        for attr in sorted(metadata_attributes):
            f.write(f":template_{attr}:\n")

if __name__ == '__main__':
    fetch_metadata()
